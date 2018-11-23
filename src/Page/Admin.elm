module Page.Admin exposing (Model, Msg(..), init, update, view)

import Data.Kinto exposing (DeletedRecord, Video)
import Data.Session exposing (LoginForm, Session, decodeSessionData, emptyLoginForm, encodeSessionData)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Kinto
import Page.Utils
import Ports
import Request.KintoUpcoming
import Request.KintoVideo


type alias Model =
    { loginForm : LoginForm
    , videoListData : VideoListData
    , errorList : List String
    }


type alias VideoList =
    Kinto.Pager Video


type alias VideoListData =
    Data.Kinto.KintoData VideoList


type Msg
    = UpdateLoginForm LoginForm
    | Login
    | Logout
    | VideoListFetched (Result Kinto.Error VideoList)
    | DiscardError Int
    | PublishVideo Video
    | VideoPublished (Result Kinto.Error Video)
    | VideoRemoved (Result Kinto.Error DeletedRecord)


init : Session -> ( Model, Cmd Msg )
init session =
    let
        initialModel =
            { loginForm = session.loginForm
            , videoListData = Data.Kinto.NotRequested
            , errorList = []
            }

        modelAndCommands =
            if session.loginForm /= Data.Session.emptyLoginForm then
                useLogin initialModel

            else
                ( initialModel, Cmd.none )
    in
    modelAndCommands


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        UpdateLoginForm loginForm ->
            ( { model | loginForm = loginForm }, Cmd.none )

        Login ->
            useLogin model

        Logout ->
            ( { model | loginForm = emptyLoginForm, videoListData = Data.Kinto.NotRequested }, Ports.logoutSession () )

        VideoListFetched (Ok videoList) ->
            ( { model | videoListData = Data.Kinto.Received videoList }, Cmd.none )

        VideoListFetched (Err err) ->
            ( { model
                | videoListData = Data.Kinto.Failed err
                , errorList = [ Kinto.errorToString err ] ++ model.errorList
              }
            , Cmd.none
            )

        DiscardError index ->
            ( { model | errorList = List.take index model.errorList ++ List.drop (index + 1) model.errorList }
            , Cmd.none
            )

        PublishVideo video ->
            ( model
            , Request.KintoVideo.publishVideo video session.loginForm.username session.loginForm.password VideoPublished
            )

        VideoPublished (Ok video) ->
            ( model
            , Request.KintoUpcoming.removeVideo video session.loginForm.username session.loginForm.password VideoRemoved
            )

        VideoPublished (Err err) ->
            ( { model
                | errorList = [ Kinto.errorToString err ] ++ model.errorList
              }
            , Cmd.none
            )

        VideoRemoved (Ok deletedRecord) ->
            let
                videoListData =
                    case model.videoListData of
                        Data.Kinto.Received videos ->
                            videos.objects
                                -- We remove the video from the list of upcoming videos, as it's just been deleted
                                |> List.filter (\video -> video.id /= deletedRecord.id)
                                -- Update the "objects" field in the Kinto.Pager record with the filtered list of videos
                                |> (\videoList -> { videos | objects = videoList })
                                |> Data.Kinto.Received

                        kintoData ->
                            kintoData
            in
            ( { model
                | videoListData = videoListData
              }
            , Cmd.none
            )

        VideoRemoved (Err err) ->
            ( { model
                | errorList = [ Kinto.errorToString err ] ++ model.errorList
              }
            , Cmd.none
            )


isLoginFormComplete : LoginForm -> Bool
isLoginFormComplete loginForm =
    loginForm.username /= "" && loginForm.password /= ""


useLogin : Model -> ( Model, Cmd Msg )
useLogin model =
    if isLoginFormComplete model.loginForm then
        ( { model | videoListData = Data.Kinto.Requested }
        , Cmd.batch
            [ Request.KintoUpcoming.getVideoList model.loginForm.username model.loginForm.password VideoListFetched
            , Ports.saveSession <| encodeSessionData model.loginForm
            ]
        )

    else
        ( model, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view _ { errorList, videoListData, loginForm } =
    ( "Administration"
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src "./logo_ca12.png", HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "Administration" ]
                , H.p [] [ H.text "Modération des vidéos et des commentaires" ]
                ]
            ]
      , H.div [ HA.class "main" ]
            [ Page.Utils.errorList errorList DiscardError
            , case videoListData of
                Data.Kinto.Received videoList ->
                    viewVideoList videoList

                _ ->
                    H.div [ HA.class "section section-white" ]
                        [ H.div [ HA.class "container" ]
                            [ viewLoginForm loginForm videoListData ]
                        ]
            ]
      ]
    )


viewVideoList : VideoList -> H.Html Msg
viewVideoList videoList =
    H.section [ HA.class "section section-grey cards" ]
        [ H.div [ HA.class "container" ]
            [ H.div [ HA.class "form__group logout-button" ]
                [ H.button
                    [ HA.class "button logout-button warning large"
                    , HE.onClick Logout
                    ]
                    [ H.text "Se déconnecter" ]
                ]
            , H.div [ HA.class "row" ]
                (videoList.objects
                    |> List.map viewVideo
                )
            ]
        ]


viewVideo : Data.Kinto.Video -> H.Html Msg
viewVideo video =
    let
        keywordsNode =
            if video.keywords /= "" then
                [ H.div [ HA.class "card__extra" ]
                    [ H.div [ HA.class "label" ]
                        [ H.text video.keywords ]
                    ]
                ]

            else
                []

        cardNodes =
            [ H.div
                [ HA.class "card__cover" ]
                [ viewVideoPlayer video.attachment ]
            , H.div
                [ HA.class "card__content" ]
                [ H.h3 [] [ H.text video.title ]
                , H.div [ HA.class "card__meta" ]
                    [ H.time [] [ H.text <| String.fromInt video.last_modified ] ]
                , H.p [] [ H.text video.description ]
                ]
            ]

        publishNode =
            [ Page.Utils.button "Publier cette vidéo" Page.Utils.NotLoading (Just <| PublishVideo video) ]
    in
    H.div
        [ HA.class "card" ]
        (cardNodes ++ keywordsNode ++ publishNode)


viewVideoPlayer : Data.Kinto.Attachment -> H.Html Msg
viewVideoPlayer attachment =
    H.video
        [ HA.src attachment.location
        , HA.type_ attachment.mimetype
        , HA.controls True
        ]
        [ H.text "Désolé, votre navigateur ne supporte pas le format de cette video" ]


viewLoginForm : LoginForm -> VideoListData -> H.Html Msg
viewLoginForm loginForm videoListData =
    let
        formComplete =
            isLoginFormComplete loginForm

        buttonState =
            if formComplete then
                case videoListData of
                    Data.Kinto.Requested ->
                        Page.Utils.Loading

                    _ ->
                        Page.Utils.NotLoading

            else
                Page.Utils.Disabled

        submitButton =
            Page.Utils.submitButton "Utiliser ces identifiants" buttonState
    in
    H.form
        [ HE.onSubmit Login ]
        [ H.h1 [] [ H.text "Formulaire de connexion" ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "username" ] [ H.text "Username" ]
            , H.input
                [ HA.type_ "text"
                , HA.id "username"
                , HA.value loginForm.username
                , HE.onInput <| \username -> UpdateLoginForm { loginForm | username = username }
                ]
                []
            ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "password" ] [ H.text "Password" ]
            , H.input
                [ HA.type_ "password"
                , HA.value loginForm.password
                , HE.onInput <| \password -> UpdateLoginForm { loginForm | password = password }
                ]
                []
            ]
        , submitButton
        ]

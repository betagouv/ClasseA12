module Page.Admin exposing (Model, Msg(..), init, update, view)

import Data.Kinto exposing (DeletedRecord, Video, VideoList, VideoListData)
import Data.Session exposing (LoginForm, Session, decodeSessionData, emptyLoginForm, encodeSessionData)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Kinto
import Page.Utils
import Ports
import Request.Kinto exposing (authClient)
import Request.KintoUpcoming
import Request.KintoVideo


type alias Model =
    { loginForm : LoginForm
    , videoListData : VideoListData
    , errorList : List String
    , publishingVideos : PublishingVideos
    , activeVideo : Maybe Data.Kinto.Video
    }


type alias PublishingVideos =
    List Video


type Msg
    = UpdateLoginForm LoginForm
    | Login
    | Logout
    | VideoListFetched (Result Kinto.Error VideoList)
    | DiscardError Int
    | PublishVideo Video
    | VideoPublished (Result Kinto.Error Video)
    | VideoRemoved Video (Result Kinto.Error DeletedRecord)
    | ToggleVideo Data.Kinto.Video


init : Session -> ( Model, Cmd Msg )
init session =
    let
        initialModel =
            { loginForm = session.loginForm
            , videoListData = Data.Kinto.NotRequested
            , errorList = []
            , publishingVideos = []
            , activeVideo = Nothing
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
            let
                client =
                    authClient session.loginForm.username session.loginForm.password
            in
            ( { model | publishingVideos = model.publishingVideos ++ [ video ] }
            , Request.KintoVideo.publishVideo video client VideoPublished
            )

        VideoPublished (Ok video) ->
            let
                client =
                    authClient session.loginForm.username session.loginForm.password
            in
            ( model
            , Request.KintoUpcoming.removeVideo video client (VideoRemoved video)
            )

        VideoPublished (Err err) ->
            ( { model
                | errorList = [ Kinto.errorToString err ] ++ model.errorList
              }
            , Cmd.none
            )

        VideoRemoved video (Ok deletedRecord) ->
            let
                videoListData =
                    case model.videoListData of
                        Data.Kinto.Received videos ->
                            videos.objects
                                -- We remove the video from the list of upcoming videos, as it's just been deleted
                                |> List.filter ((/=) video)
                                -- Update the "objects" field in the Kinto.Pager record with the filtered list of videos
                                |> (\videoList -> { videos | objects = videoList })
                                |> Data.Kinto.Received

                        kintoData ->
                            kintoData

                publishingVideos =
                    model.publishingVideos
                        |> List.filter ((/=) video)
            in
            ( { model
                | videoListData = videoListData
                , publishingVideos = publishingVideos
              }
            , Cmd.none
            )

        VideoRemoved video (Err err) ->
            ( { model
                | errorList = [ Kinto.errorToString err ] ++ model.errorList
              }
            , Cmd.none
            )

        ToggleVideo video ->
            let
                activeVideo =
                    case model.activeVideo of
                        -- Toggle the active video
                        Just v ->
                            Nothing

                        Nothing ->
                            Just video
            in
            ( { model | activeVideo = activeVideo }, Cmd.none )


isLoginFormComplete : LoginForm -> Bool
isLoginFormComplete loginForm =
    loginForm.username /= "" && loginForm.password /= ""


useLogin : Model -> ( Model, Cmd Msg )
useLogin model =
    if isLoginFormComplete model.loginForm then
        let
            client =
                authClient model.loginForm.username model.loginForm.password
        in
        ( { model | videoListData = Data.Kinto.Requested }
        , Cmd.batch
            [ Request.KintoUpcoming.getVideoList client VideoListFetched
            , Ports.saveSession <| encodeSessionData model.loginForm
            ]
        )

    else
        ( model, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view _ { errorList, videoListData, loginForm, publishingVideos, activeVideo } =
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
                    viewVideoList publishingVideos activeVideo videoList

                _ ->
                    H.div [ HA.class "section section-white" ]
                        [ H.div [ HA.class "container" ]
                            [ viewLoginForm loginForm videoListData ]
                        ]
            ]
      ]
    )


viewVideoList : PublishingVideos -> Maybe Data.Kinto.Video -> VideoList -> H.Html Msg
viewVideoList publishingVideos activeVideo videoList =
    H.section [ HA.class "section section-grey cards" ]
        [ H.div [ HA.class "container" ]
            [ H.div [ HA.class "form__group logout-button" ]
                [ H.button
                    [ HA.class "button logout-button warning large"
                    , HE.onClick Logout
                    ]
                    [ H.text "Se déconnecter" ]
                ]
            , Page.Utils.viewVideoModal ToggleVideo activeVideo
            , H.div [ HA.class "row" ]
                (videoList.objects
                    |> List.map (viewVideo publishingVideos)
                )
            ]
        ]


viewVideo : PublishingVideos -> Data.Kinto.Video -> H.Html Msg
viewVideo publishingVideos video =
    let
        buttonState =
            if List.member video publishingVideos then
                Page.Utils.Loading

            else
                Page.Utils.NotLoading

        publishNode =
            [ Page.Utils.button "Publier cette vidéo" buttonState (Just <| PublishVideo video) ]
    in
    Page.Utils.viewVideo (ToggleVideo video) publishNode video


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

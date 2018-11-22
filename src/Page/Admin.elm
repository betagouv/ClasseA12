module Page.Admin exposing (Model, Msg(..), init, update, view)

import Data.Kinto exposing (Video)
import Data.Session exposing (LoginForm, Session, decodeSessionData, emptyLoginForm, encodeSessionData)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Kinto
import Page.Utils
import Ports
import Request.KintoUpcoming


type alias Model =
    { loginForm : LoginForm
    , videoList : VideoListData
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


init : Session -> ( Model, Cmd Msg )
init session =
    ( { loginForm = emptyLoginForm
      , videoList = Data.Kinto.NotRequested
      , errorList = []
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        UpdateLoginForm loginForm ->
            ( { model | loginForm = loginForm }, Cmd.none )

        Login ->
            useLogin model

        Logout ->
            ( { model | loginForm = emptyLoginForm }, Ports.logoutSession () )

        VideoListFetched (Ok videoList) ->
            ( { model | videoList = Data.Kinto.Received videoList }, Cmd.none )

        VideoListFetched (Err err) ->
            ( { model
                | videoList = Data.Kinto.Failed err
                , errorList = [ Kinto.errorToString err ] ++ model.errorList
              }
            , Cmd.none
            )

        DiscardError index ->
            ( { model | errorList = List.take index model.errorList ++ List.drop (index + 1) model.errorList }
            , Cmd.none
            )


isLoginFormComplete : LoginForm -> Bool
isLoginFormComplete loginForm =
    loginForm.serverURL /= "" && loginForm.username /= "" && loginForm.password /= ""


useLogin : Model -> ( Model, Cmd Msg )
useLogin model =
    if isLoginFormComplete model.loginForm then
        let
            client =
                Kinto.client model.loginForm.serverURL (Kinto.Basic model.loginForm.username model.loginForm.password)
        in
        ( { model | videoList = Data.Kinto.Requested }
        , Cmd.batch
            [ Request.KintoUpcoming.getVideoList model.loginForm.username model.loginForm.password VideoListFetched
            , Ports.saveSession <| encodeSessionData model.loginForm
            ]
        )

    else
        ( model, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view _ model =
    ( "Administration"
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src "./logo_ca12.png", HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "Administration" ]
                , H.p [] [ H.text "Modération des vidéos et des commentaires" ]
                ]
            ]
      , H.div [ HA.class "main" ]
            [ H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ viewErrorList model.errorList
                    , case model.videoList of
                        Data.Kinto.Received videoList ->
                            viewVideoList videoList

                        _ ->
                            viewLoginForm model.loginForm model.videoList
                    ]
                ]
            ]
      ]
    )


viewVideoList : VideoList -> H.Html Msg
viewVideoList videoList =
    H.div [] [ H.text "#list of videos here#" ]


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
            [ H.label [ HA.for "serverURL" ] [ H.text "Server URL" ]
            , H.input
                [ HA.type_ "text"
                , HA.id "serverURL"
                , HA.value loginForm.serverURL
                , HE.onInput <| \serverURL -> UpdateLoginForm { loginForm | serverURL = serverURL }
                ]
                []
            ]
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


viewErrorList : List String -> H.Html Msg
viewErrorList errorList =
    H.div []
        (errorList
            |> List.indexedMap
                (\index error ->
                    H.div [ HA.class "notification error closable" ]
                        [ H.button
                            [ HA.class "close"
                            , HE.onClick <| DiscardError index
                            ]
                            [ H.i [ HA.class "fa fa-times" ] [] ]
                        , H.text <| error
                        ]
                )
        )

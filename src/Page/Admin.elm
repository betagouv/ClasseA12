module Page.Admin exposing (Model, Msg(..), init, update, view)

import Data.Kinto exposing (Video)
import Data.Session exposing (LoginForm, Session, decodeSessionData, emptyLoginForm, encodeSessionData)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Kinto
import Ports
import Request.KintoUpcoming


type alias Model =
    { loginForm : LoginForm
    , videoList : VideoListData
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


init : Session -> ( Model, Cmd Msg )
init session =
    ( { loginForm = emptyLoginForm
      , videoList = Data.Kinto.NotRequested
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

        VideoListFetched _ ->
            ( model, Cmd.none )


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
                    [ case model.videoList of
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
                        Loading

                    _ ->
                        NotLoading

            else
                Disabled

        submitButton =
            loadingButton "Utiliser ces identifiants" buttonState
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


type ButtonState
    = Disabled
    | Loading
    | NotLoading


loadingButton : String -> ButtonState -> H.Html Msg
loadingButton label buttonState =
    let
        loadingAttrs =
            case buttonState of
                Disabled ->
                    [ HA.type_ "submit"
                    , HA.class "button"
                    , HA.disabled True
                    ]

                Loading ->
                    [ HA.type_ "submit"
                    , HA.class "button button-loader"
                    , HA.disabled True
                    ]

                NotLoading ->
                    [ HA.type_ "submit"
                    , HA.class "button"
                    ]
    in
    H.button
        loadingAttrs
        [ H.text label ]

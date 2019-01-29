module Page.Login exposing (Model, Msg(..), init, update, view)

import Data.Kinto
import Data.Session exposing (LoginForm, Session, decodeSessionData, emptyLoginForm, encodeSessionData)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Kinto
import Page.Utils
import Ports
import Request.Kinto exposing (authClient)
import Request.KintoUserInfo


type alias Model =
    { loginForm : LoginForm
    , error : Maybe String
    , userInfoData : Data.Kinto.KintoData Data.Kinto.UserInfo
    }


type Msg
    = UpdateLoginForm LoginForm
    | Login
    | Logout
    | DiscardError
    | UserInfoReceived (Result Http.Error Data.Kinto.UserInfo)


init : Session -> ( Model, Cmd Msg )
init session =
    let
        initialModel =
            { loginForm = session.loginForm
            , error = Nothing
            , userInfoData = Data.Kinto.NotRequested
            }

        modelAndCommands =
            if session.loginForm /= Data.Session.emptyLoginForm then
                useLogin session.kintoURL initialModel

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
            useLogin session.kintoURL model

        Logout ->
            ( { model | loginForm = emptyLoginForm, userInfoData = Data.Kinto.NotRequested }, Cmd.none )

        DiscardError ->
            ( { model | error = Nothing }, Cmd.none )

        UserInfoReceived (Ok userInfo) ->
            ( { model | error = Nothing, userInfoData = Data.Kinto.Received userInfo }
            , Cmd.none
            )

        UserInfoReceived (Err error) ->
            ( { model | error = Just "Connexion échouée", userInfoData = Data.Kinto.NotRequested }, Cmd.none )


isLoginFormComplete : LoginForm -> Bool
isLoginFormComplete loginForm =
    loginForm.username /= "" && loginForm.password /= ""


useLogin : String -> Model -> ( Model, Cmd Msg )
useLogin kintoURL model =
    if isLoginFormComplete model.loginForm then
        ( { model | userInfoData = Data.Kinto.Requested }
        , Request.KintoUserInfo.getUserInfo kintoURL model.loginForm.username model.loginForm.password UserInfoReceived
        )

    else
        ( model, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view _ { error, loginForm, userInfoData } =
    ( "Connexion"
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src "/logo_ca12.png", HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "Connexion" ]
                ]
            ]
      , H.div [ HA.class "main" ]
            [ viewError error
            , case userInfoData of
                Data.Kinto.Received userInfo ->
                    H.div [] [ H.text "Vous êtes maintenant connecté" ]

                _ ->
                    H.div [ HA.class "section section-white" ]
                        [ H.div [ HA.class "container" ]
                            [ viewLoginForm loginForm userInfoData ]
                        ]
            ]
      ]
    )


viewLoginForm : LoginForm -> Data.Kinto.UserInfoData -> H.Html Msg
viewLoginForm loginForm userInfoData =
    let
        formComplete =
            isLoginFormComplete loginForm

        buttonState =
            if formComplete then
                case userInfoData of
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


viewError : Maybe String -> H.Html Msg
viewError maybeError =
    case maybeError of
        Just error ->
            Page.Utils.errorNotification [ H.text error ] DiscardError

        Nothing ->
            H.div [] []

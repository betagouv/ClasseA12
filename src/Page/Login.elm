module Page.Login exposing (Model, Msg(..), init, update, view)

import Data.Kinto
import Data.Session exposing (Session, UserData, decodeUserData, emptyUserData, encodeUserData)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Kinto
import Page.Common.Notifications as Notifications
import Page.Utils
import Request.KintoUserInfo
import Route


type alias Model =
    { loginForm : UserData
    , notifications : Notifications.Model
    , userInfoData : Data.Kinto.KintoData Data.Kinto.UserInfo
    }


type Msg
    = UpdateLoginForm UserData
    | Login
    | NotificationMsg Notifications.Msg
    | UserInfoReceived (Result Http.Error Data.Kinto.UserInfo)


init : Session -> ( Model, Cmd Msg )
init session =
    let
        initialModel =
            { loginForm = session.userData
            , userInfoData = Data.Kinto.NotRequested
            , notifications = Notifications.init
            }

        modelAndCommands =
            if Data.Session.isLoggedIn session.userData then
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

        UserInfoReceived (Ok userInfo) ->
            ( { model | userInfoData = Data.Kinto.Received userInfo }
            , Cmd.none
            )

        UserInfoReceived (Err error) ->
            let
                kintoError =
                    Kinto.extractError error

                message =
                    case kintoError of
                        Kinto.KintoError code _ _ ->
                            if code == 403 then
                                "Est-ce que l'email et le mot de passe sont corrects ? Est-ce que le compte existe ?"

                            else
                                Kinto.errorToString kintoError

                        _ ->
                            Kinto.errorToString kintoError
            in
            ( { model
                | notifications =
                    "Connection échouée : "
                        ++ message
                        |> Notifications.addError model.notifications
                , userInfoData = Data.Kinto.NotRequested
              }
            , Cmd.none
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }, Cmd.none )


isLoginFormComplete : UserData -> Bool
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
view _ { notifications, loginForm, userInfoData } =
    ( "Connexion"
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src "/logo_ca12.png", HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "Connexion" ]
                ]
            ]
      , H.div [ HA.class "main" ]
            [ H.map NotificationMsg (Notifications.view notifications)
            , case userInfoData of
                Data.Kinto.Received userInfo ->
                    H.div [] [ H.text "Vous êtes maintenant connecté" ]

                _ ->
                    H.div [ HA.class "section section-white" ]
                        [ H.div [ HA.class "container" ]
                            [ viewLoginForm loginForm userInfoData
                            ]
                        ]
            ]
      ]
    )


viewLoginForm : UserData -> Data.Kinto.UserInfoData -> H.Html Msg
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
            [ H.label [ HA.for "username" ] [ H.text "Email de connexion" ]
            , H.input
                [ HA.type_ "text"
                , HA.id "username"
                , HA.value loginForm.username
                , HE.onInput <| \username -> UpdateLoginForm { loginForm | username = username }
                ]
                []
            ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "password" ] [ H.text "Mot de passe" ]
            , H.input
                [ HA.type_ "password"
                , HA.value loginForm.password
                , HE.onInput <| \password -> UpdateLoginForm { loginForm | password = password }
                ]
                []
            ]
        , submitButton
        , H.p []
            [ H.a [ Route.href Route.Register ] [ H.text "Je n'ai pas encore de compte" ]
            , H.text " - "
            , H.a [ Route.href Route.ResetPassword ] [ H.text "J'ai oublié mon mot de passe" ]
            ]
        ]

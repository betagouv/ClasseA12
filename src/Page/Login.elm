module Page.Login exposing (Model, Msg(..), init, update, view)

import Data.PeerTube as PeerTube
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Page.Common.Components
import Page.Common.Notifications as Notifications
import Request.PeerTube
import Route


type alias Model =
    { title : String
    , loginForm : LoginForm
    , notifications : Notifications.Model
    , userInfoData : PeerTube.RemoteData PeerTube.UserInfo
    }


type alias LoginForm =
    { username : String
    , password : String
    }


emptyLoginForm =
    { username = "", password = "" }


type Msg
    = UpdateLoginForm LoginForm
    | Login
    | NotificationMsg Notifications.Msg
    | UserTokenReceived (Result Http.Error PeerTube.UserToken)
    | UserInfoReceived PeerTube.UserToken (Result Http.Error PeerTube.UserInfo)


init : Session -> ( Model, Cmd Msg )
init session =
    let
        initialModel =
            { title = "Connexion"
            , loginForm = emptyLoginForm
            , userInfoData = PeerTube.NotRequested
            , notifications = Notifications.init
            }
    in
    ( initialModel, Cmd.none )


update : Session -> Msg -> Model -> ( Model, Cmd Msg, Maybe Data.Session.Msg )
update session msg model =
    case msg of
        UpdateLoginForm loginForm ->
            ( { model | loginForm = loginForm }
            , Cmd.none
            , Nothing
            )

        Login ->
            useLogin session.peerTubeURL model

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }
            , Cmd.none
            , Nothing
            )

        UserTokenReceived (Ok userToken) ->
            ( model
            , Request.PeerTube.getUserInfo userToken.access_token session.peerTubeURL (UserInfoReceived userToken)
            , Nothing
            )

        UserTokenReceived (Err error) ->
            ( { model
                | notifications =
                    "Connection échouée"
                        |> Notifications.addError model.notifications
                , userInfoData = PeerTube.NotRequested
              }
            , Cmd.none
            , Nothing
            )

        UserInfoReceived userToken (Ok userInfo) ->
            ( { model | userInfoData = PeerTube.Received userInfo }
            , Cmd.none
            , Just <| Data.Session.Login userToken userInfo
            )

        UserInfoReceived _ (Err error) ->
            ( { model
                | notifications =
                    "Connection échouée"
                        |> Notifications.addError model.notifications
                , userInfoData = PeerTube.NotRequested
              }
            , Cmd.none
            , Nothing
            )


isLoginFormComplete : LoginForm -> Bool
isLoginFormComplete loginForm =
    loginForm.username /= "" && loginForm.password /= ""


useLogin : String -> Model -> ( Model, Cmd Msg, Maybe Data.Session.Msg )
useLogin serverURL model =
    if isLoginFormComplete model.loginForm then
        ( { model | userInfoData = PeerTube.Requested }
        , Request.PeerTube.login model.loginForm.username model.loginForm.password serverURL UserTokenReceived
        , Nothing
        )

    else
        ( model, Cmd.none, Nothing )


view : Session -> Model -> Page.Common.Components.Document Msg
view session { title, notifications, loginForm, userInfoData } =
    { title = title
    , pageTitle = title
    , pageSubTitle = ""
    , body =
        [ H.map NotificationMsg (Notifications.view notifications)
        , case userInfoData of
            PeerTube.Received userInfo ->
                H.div [] [ H.text "Vous êtes maintenant connecté" ]

            _ ->
                H.div [ HA.class "section section-white" ]
                    [ H.div [ HA.class "container" ]
                        [ viewLoginForm loginForm userInfoData
                        ]
                    ]
        ]
    }


viewLoginForm : LoginForm -> PeerTube.RemoteData PeerTube.UserInfo -> H.Html Msg
viewLoginForm loginForm userInfoData =
    let
        formComplete =
            isLoginFormComplete loginForm

        buttonState =
            if formComplete then
                case userInfoData of
                    PeerTube.Requested ->
                        Page.Common.Components.Loading

                    _ ->
                        Page.Common.Components.NotLoading

            else
                Page.Common.Components.Disabled

        submitButton =
            Page.Common.Components.submitButton "Utiliser ces identifiants" buttonState
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

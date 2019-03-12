module Page.SetNewPassword exposing (Model, Msg(..), init, update, view)

import Data.Kinto
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Kinto
import Page.Common.Components
import Page.Common.Notifications as Notifications
import Request.KintoAccount
import Route


type alias Model =
    { email : String
    , temporaryPassword : String
    , setNewPasswordForm : SetNewPasswordForm
    , notifications : Notifications.Model
    , userInfoData : Data.Kinto.UserInfoData
    }


type alias SetNewPasswordForm =
    { password : String
    , password2 : String
    }


emptySetNewPasswordForm : SetNewPasswordForm
emptySetNewPasswordForm =
    { password = "", password2 = "" }


type Msg
    = UpdateSetNewPasswordForm SetNewPasswordForm
    | SetNewPassword
    | NotificationMsg Notifications.Msg
    | NewPasswordSet (Result Http.Error Data.Kinto.UserInfo)


init : String -> String -> Session -> ( Model, Cmd Msg )
init email temporaryPassword session =
    ( { email = email
      , temporaryPassword = temporaryPassword
      , setNewPasswordForm = emptySetNewPasswordForm
      , notifications = Notifications.init
      , userInfoData = Data.Kinto.NotRequested
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        UpdateSetNewPasswordForm setNewPasswordForm ->
            ( { model | setNewPasswordForm = setNewPasswordForm }, Cmd.none )

        SetNewPassword ->
            setNewPassword session.kintoURL model

        NewPasswordSet (Ok userInfo) ->
            ( { model | userInfoData = Data.Kinto.Received userInfo }
            , Cmd.none
            )

        NewPasswordSet (Err error) ->
            let
                kintoError =
                    Kinto.extractError error
            in
            ( { model
                | notifications =
                    "Changement du mot de passe échouée : "
                        ++ Kinto.errorToString kintoError
                        |> Notifications.addError model.notifications
                , userInfoData = Data.Kinto.NotRequested
              }
            , Cmd.none
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }, Cmd.none )


isSetNewPasswordFormComplete : SetNewPasswordForm -> Bool
isSetNewPasswordFormComplete setNewPasswordForm =
    setNewPasswordForm.password /= "" && setNewPasswordForm.password == setNewPasswordForm.password2


setNewPassword : String -> Model -> ( Model, Cmd Msg )
setNewPassword kintoURL model =
    if isSetNewPasswordFormComplete model.setNewPasswordForm then
        ( { model | userInfoData = Data.Kinto.Requested }
        , Request.KintoAccount.setNewPassword kintoURL model.email model.temporaryPassword model.setNewPasswordForm.password NewPasswordSet
        )

    else
        ( model, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view session { email, notifications, setNewPasswordForm, userInfoData } =
    ( "Nouveau mot de passe"
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src session.staticFiles.logo_ca12, HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "Nouveau mot de passe" ]
                ]
            ]
      , H.div [ HA.class "main" ]
            [ H.map NotificationMsg (Notifications.view notifications)
            , H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ case userInfoData of
                        Data.Kinto.Received userInfo ->
                            H.div []
                                [ H.text "Votre nouveau mot de passe a été enregistré, vous pouvez maintenant "
                                , H.a [ Route.href Route.Login ] [ H.text "vous connecter en utilisant ce mot de passe." ]
                                ]

                        _ ->
                            viewSetNewPasswordForm email setNewPasswordForm userInfoData
                    ]
                ]
            ]
      ]
    )


viewSetNewPasswordForm : String -> SetNewPasswordForm -> Data.Kinto.UserInfoData -> H.Html Msg
viewSetNewPasswordForm email setNewPasswordForm userInfoData =
    let
        formComplete =
            isSetNewPasswordFormComplete setNewPasswordForm

        buttonState =
            if formComplete then
                case userInfoData of
                    Data.Kinto.Requested ->
                        Page.Common.Components.Loading

                    _ ->
                        Page.Common.Components.NotLoading

            else
                Page.Common.Components.Disabled

        submitButton =
            Page.Common.Components.submitButton "Enregistrer ce nouveau mot de passe" buttonState
    in
    H.form
        [ HE.onSubmit SetNewPassword ]
        [ H.h1 [] [ H.text <| "Enregistrer un nouveau mot de passe pour " ++ email ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "password" ] [ H.text "Nouveau mot de passe" ]
            , H.input
                [ HA.type_ "password"
                , HA.id "password"
                , HA.value setNewPasswordForm.password
                , HE.onInput <| \password -> UpdateSetNewPasswordForm { setNewPasswordForm | password = password }
                ]
                []
            ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "password2" ] [ H.text "Confirmer le mot de passe" ]
            , H.input
                [ HA.type_ "password"
                , HA.id "password2"
                , HA.value setNewPasswordForm.password2
                , HE.onInput <| \password2 -> UpdateSetNewPasswordForm { setNewPasswordForm | password2 = password2 }
                ]
                []
            ]
        , submitButton
        ]

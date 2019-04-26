module Page.ResetPassword exposing (Model, Msg(..), init, update, view)

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


type alias Model =
    { title : String
    , resetForm : ResetForm
    , notifications : Notifications.Model
    , passwordReset : Data.Kinto.KintoData Request.KintoAccount.PasswordReset
    }


type alias ResetForm =
    { email : String
    }


emptyResetForm : ResetForm
emptyResetForm =
    { email = "" }


type Msg
    = UpdateResetForm ResetForm
    | ResetPassword
    | NotificationMsg Notifications.Msg
    | PasswordReset (Result Http.Error Request.KintoAccount.PasswordReset)


init : Session -> ( Model, Cmd Msg )
init session =
    ( { title = "Oubli du mot de passe"
      , resetForm = emptyResetForm
      , notifications = Notifications.init
      , passwordReset = Data.Kinto.NotRequested
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        UpdateResetForm resetForm ->
            ( { model | resetForm = resetForm }, Cmd.none )

        ResetPassword ->
            resetPassword session.kintoURL model

        PasswordReset (Ok passwordReset) ->
            ( { model | passwordReset = Data.Kinto.Received passwordReset }
            , Cmd.none
            )

        PasswordReset (Err error) ->
            let
                kintoError =
                    Kinto.extractError error
            in
            ( { model
                | notifications =
                    "Réinitialisation du mot de passe échouée : "
                        ++ Kinto.errorToString kintoError
                        |> Notifications.addError model.notifications
                , passwordReset = Data.Kinto.NotRequested
              }
            , Cmd.none
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }, Cmd.none )


isResetFormComplete : ResetForm -> Bool
isResetFormComplete resetForm =
    resetForm.email /= ""


resetPassword : String -> Model -> ( Model, Cmd Msg )
resetPassword kintoURL model =
    if isResetFormComplete model.resetForm then
        ( { model | passwordReset = Data.Kinto.Requested }
        , Request.KintoAccount.resetPassword kintoURL model.resetForm.email PasswordReset
        )

    else
        ( model, Cmd.none )


view : Session -> Model -> Page.Common.Components.Document Msg
view session { title, notifications, resetForm, passwordReset } =
    { title = title
    , pageTitle = title
    , pageSubTitle = ""
    , body =
        [ H.map NotificationMsg (Notifications.view notifications)
        , H.div [ HA.class "section section-white" ]
            [ H.div [ HA.class "container" ]
                [ case passwordReset of
                    Data.Kinto.Received message ->
                        H.div []
                            [ H.text "Un lien de réinitialisation du mot de passe vous a été envoyé par email"
                            ]

                    _ ->
                        viewResetForm resetForm passwordReset
                ]
            ]
        ]
    }


viewResetForm : ResetForm -> Data.Kinto.KintoData Request.KintoAccount.PasswordReset -> H.Html Msg
viewResetForm resetForm passwordReset =
    let
        formComplete =
            isResetFormComplete resetForm

        buttonState =
            if formComplete then
                case passwordReset of
                    Data.Kinto.Requested ->
                        Page.Common.Components.Loading

                    _ ->
                        Page.Common.Components.NotLoading

            else
                Page.Common.Components.Disabled

        submitButton =
            Page.Common.Components.submitButton "M'envoyer un mail de réinitialisation" buttonState
    in
    H.form
        [ HE.onSubmit ResetPassword ]
        [ H.h1 [] [ H.text "Demande de réinitialisation du mot de passe" ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "email" ] [ H.text "Email du compte dont le mot de passe est oublié" ]
            , H.input
                [ HA.type_ "email"
                , HA.id "email"
                , HA.value resetForm.email
                , HE.onInput <| \email -> UpdateResetForm { resetForm | email = email }
                ]
                []
            ]
        , submitButton
        ]

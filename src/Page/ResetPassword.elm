module Page.ResetPassword exposing (Model, Msg(..), init, update, view)

import Data.PeerTube
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Page.Common.Components
import Page.Common.Notifications as Notifications
import Request.PeerTube


type alias Model =
    { title : String
    , resetForm : ResetForm
    , notifications : Notifications.Model
    , passwordReset : Data.PeerTube.RemoteData String
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
    | PasswordReset (Result Http.Error String)


init : Session -> ( Model, Cmd Msg )
init _ =
    ( { title = "Oubli du mot de passe"
      , resetForm = emptyResetForm
      , notifications = Notifications.init
      , passwordReset = Data.PeerTube.NotRequested
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        UpdateResetForm resetForm ->
            ( { model | resetForm = resetForm }, Cmd.none )

        ResetPassword ->
            resetPassword session.peerTubeURL model

        PasswordReset (Ok _) ->
            ( { model | passwordReset = Data.PeerTube.Received "Un lien de réinitialisation du mot de passe vous a été envoyé par email" }
            , Cmd.none
            )

        PasswordReset (Err _) ->
            ( { model
                | notifications =
                    "Demande de réinitialisation du mot de passe échouée"
                        |> Notifications.addError model.notifications
                , passwordReset = Data.PeerTube.NotRequested
              }
            , Cmd.none
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }, Cmd.none )


isResetFormComplete : ResetForm -> Bool
isResetFormComplete resetForm =
    resetForm.email /= ""


resetPassword : String -> Model -> ( Model, Cmd Msg )
resetPassword peerTubeURL model =
    if isResetFormComplete model.resetForm then
        ( { model | passwordReset = Data.PeerTube.Requested }
        , Request.PeerTube.askPasswordReset model.resetForm.email peerTubeURL PasswordReset
        )

    else
        ( model, Cmd.none )


view : Session -> Model -> Page.Common.Components.Document Msg
view _ { title, notifications, resetForm, passwordReset } =
    { title = title
    , pageTitle = title
    , pageSubTitle = ""
    , body =
        [ H.map NotificationMsg (Notifications.view notifications)
        , H.div [ HA.class "section " ]
            [ H.div [ HA.class "container" ]
                [ case passwordReset of
                    Data.PeerTube.Received message ->
                        H.div []
                            [ H.text message
                            ]

                    _ ->
                        viewResetForm resetForm passwordReset
                ]
            ]
        ]
    }


viewResetForm : ResetForm -> Data.PeerTube.RemoteData String -> H.Html Msg
viewResetForm resetForm passwordReset =
    let
        formComplete =
            isResetFormComplete resetForm

        buttonState =
            if formComplete then
                case passwordReset of
                    Data.PeerTube.Requested ->
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

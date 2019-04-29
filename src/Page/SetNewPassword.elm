module Page.SetNewPassword exposing (Model, Msg(..), init, update, view)

import Data.PeerTube
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
    , userID : String
    , verificationString : String
    , setNewPasswordForm : SetNewPasswordForm
    , notifications : Notifications.Model
    , newPasswordRequest : Data.PeerTube.RemoteData String
    }


type alias SetNewPasswordForm =
    { password : String
    }


emptySetNewPasswordForm : SetNewPasswordForm
emptySetNewPasswordForm =
    { password = "" }


type Msg
    = UpdateSetNewPasswordForm SetNewPasswordForm
    | SetNewPassword
    | NotificationMsg Notifications.Msg
    | NewPasswordSet (Result Http.Error String)


init : String -> String -> Session -> ( Model, Cmd Msg )
init userID verificationString session =
    ( { title = "Nouveau mot de passe"
      , userID = userID
      , verificationString = verificationString
      , setNewPasswordForm = emptySetNewPasswordForm
      , notifications = Notifications.init
      , newPasswordRequest = Data.PeerTube.NotRequested
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        UpdateSetNewPasswordForm setNewPasswordForm ->
            ( { model | setNewPasswordForm = setNewPasswordForm }, Cmd.none )

        SetNewPassword ->
            setNewPassword session.peerTubeURL model

        NewPasswordSet (Ok userInfo) ->
            ( { model | newPasswordRequest = Data.PeerTube.Received "Votre nouveau mot de passe a été enregistré" }
            , Cmd.none
            )

        NewPasswordSet (Err error) ->
            ( { model
                | notifications =
                    "Changement du mot de passe échoué"
                        |> Notifications.addError model.notifications
                , newPasswordRequest = Data.PeerTube.NotRequested
              }
            , Cmd.none
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }, Cmd.none )


isSetNewPasswordFormComplete : SetNewPasswordForm -> Bool
isSetNewPasswordFormComplete setNewPasswordForm =
    setNewPasswordForm.password /= ""


setNewPassword : String -> Model -> ( Model, Cmd Msg )
setNewPassword peerTubeURL model =
    if isSetNewPasswordFormComplete model.setNewPasswordForm then
        ( { model | newPasswordRequest = Data.PeerTube.Requested }
        , Request.PeerTube.changePassword model.userID model.verificationString model.setNewPasswordForm.password peerTubeURL NewPasswordSet
        )

    else
        ( model, Cmd.none )


view : Session -> Model -> Page.Common.Components.Document Msg
view session { title, notifications, setNewPasswordForm, newPasswordRequest } =
    { title = title
    , pageTitle = title
    , pageSubTitle = ""
    , body =
        [ H.map NotificationMsg (Notifications.view notifications)
        , H.div [ HA.class "section section-white" ]
            [ H.div [ HA.class "container" ]
                [ case newPasswordRequest of
                    Data.PeerTube.Received message ->
                        H.div []
                            [ H.text message
                            , H.text ", vous pouvez maintenant "
                            , H.a [ Route.href Route.Login ] [ H.text "vous connecter en utilisant ce mot de passe." ]
                            ]

                    _ ->
                        viewSetNewPasswordForm setNewPasswordForm newPasswordRequest
                ]
            ]
        ]
    }


viewSetNewPasswordForm : SetNewPasswordForm -> Data.PeerTube.RemoteData String -> H.Html Msg
viewSetNewPasswordForm setNewPasswordForm newPasswordRequest =
    let
        formComplete =
            isSetNewPasswordFormComplete setNewPasswordForm

        buttonState =
            if formComplete then
                case newPasswordRequest of
                    Data.PeerTube.Requested ->
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
        [ H.h1 [] [ H.text <| "Enregistrer un nouveau mot de passe" ]
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
        , submitButton
        ]

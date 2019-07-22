module Page.Activate exposing (Model, Msg(..), init, update, view)

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
    , notifications : Notifications.Model
    , activationRequest : Data.PeerTube.RemoteData String
    }


type Msg
    = Activate
    | NotificationMsg Notifications.Msg
    | AccountActivated (Result Http.Error String)


init : String -> String -> Session -> ( Model, Cmd Msg )
init userID verificationString _ =
    ( { title = "Activation"
      , userID = userID
      , verificationString = verificationString
      , notifications = Notifications.init
      , activationRequest = Data.PeerTube.NotRequested
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        Activate ->
            ( { model | activationRequest = Data.PeerTube.Requested }
            , Request.PeerTube.activate model.userID model.verificationString session.peerTubeURL AccountActivated
            )

        AccountActivated (Ok _) ->
            ( { model | activationRequest = Data.PeerTube.Received "Votre compte a été activé !" }
            , Cmd.none
            )

        AccountActivated (Err _) ->
            ( { model
                | notifications =
                    "Activation échouée"
                        |> Notifications.addError model.notifications
                , activationRequest = Data.PeerTube.NotRequested
              }
            , Cmd.none
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }, Cmd.none )


view : Session -> Model -> Page.Common.Components.Document Msg
view _ { title, notifications, activationRequest } =
    { title = title
    , pageTitle = title
    , pageSubTitle = ""
    , body =
        [ H.map NotificationMsg (Notifications.view notifications)
        , H.div [ HA.class "section " ]
            [ H.div [ HA.class "container" ]
                [ case activationRequest of
                    Data.PeerTube.Received message ->
                        H.div []
                            [ H.text message
                            , H.text " Vous pouvez maintenant "
                            , H.a [ Route.href Route.Login ] [ H.text "vous connecter." ]
                            ]

                    _ ->
                        viewActivationForm activationRequest
                ]
            ]
        ]
    }


viewActivationForm : Data.PeerTube.RemoteData String -> H.Html Msg
viewActivationForm activationRequest =
    let
        buttonState =
            case activationRequest of
                Data.PeerTube.Requested ->
                    Page.Common.Components.Loading

                _ ->
                    Page.Common.Components.NotLoading

        submitButton =
            Page.Common.Components.submitButton "Activer ce compte" buttonState
    in
    H.form
        [ HE.onSubmit Activate ]
        [ H.h1 [] [ H.text <| "Activation du compte" ]
        , submitButton
        ]

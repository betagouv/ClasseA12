module Page.Activate exposing (Model, Msg(..), init, update, view)

import Data.Kinto
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Kinto
import Page.Common.Notifications as Notifications
import Page.Utils
import Ports
import Request.Kinto exposing (authClient)
import Request.KintoAccount
import Route


type alias Model =
    { userID : String
    , activationKey : String
    , notifications : Notifications.Model
    , userInfoData : Data.Kinto.KintoData Request.KintoAccount.UserInfo
    }


type Msg
    = Activate
    | NotificationMsg Notifications.Msg
    | AccountActivated (Result Http.Error Request.KintoAccount.UserInfo)


init : String -> String -> Session -> ( Model, Cmd Msg )
init userID activationKey session =
    ( { userID = userID
      , activationKey = activationKey
      , notifications = Notifications.init
      , userInfoData = Data.Kinto.NotRequested
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        Activate ->
            ( { model | userInfoData = Data.Kinto.Requested }
            , Request.KintoAccount.activate session.kintoURL model.userID model.activationKey AccountActivated
            )

        AccountActivated (Ok userInfo) ->
            ( { model | userInfoData = Data.Kinto.Received userInfo }
            , Cmd.none
            )

        AccountActivated (Err error) ->
            let
                kintoError =
                    Kinto.extractError error
            in
            ( { model
                | notifications =
                    "Activation échouée : "
                        ++ Kinto.errorToString kintoError
                        |> Notifications.addError model.notifications
                , userInfoData = Data.Kinto.NotRequested
              }
            , Cmd.none
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view _ { notifications, userInfoData, userID } =
    ( "Activation"
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src "/logo_ca12.png", HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "Activation" ]
                ]
            ]
      , H.div [ HA.class "main" ]
            [ H.map NotificationMsg (Notifications.view notifications)
            , H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ case userInfoData of
                        Data.Kinto.Received userInfo ->
                            H.div []
                                [ H.text "Votre compte a été activé ! Vous pouvez maintenant "
                                , H.a [ Route.href Route.Login ] [ H.text "vous connecter pour créer votre profil." ]
                                ]

                        _ ->
                            viewActivationForm userID userInfoData
                    ]
                ]
            ]
      ]
    )


viewActivationForm : String -> Request.KintoAccount.UserInfoData -> H.Html Msg
viewActivationForm userID userInfoData =
    let
        buttonState =
            case userInfoData of
                Data.Kinto.Requested ->
                    Page.Utils.Loading

                _ ->
                    Page.Utils.NotLoading

        submitButton =
            Page.Utils.submitButton "Activer ce compte" buttonState
    in
    H.form
        [ HE.onSubmit Activate ]
        [ H.h1 [] [ H.text <| "Activation du compte " ++ userID ]
        , submitButton
        ]

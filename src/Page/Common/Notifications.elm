module Page.Common.Notifications exposing (Model, Msg(..), addError, addInfo, addSuccess, init, update, view)

import Html as H
import Html.Attributes as HA
import Html.Events as HE


type alias Model =
    List Notification


type Notification
    = Error String
    | Success String
    | Info String


init : Model
init =
    []


type Msg
    = AddError String
    | AddSuccess String
    | AddInfo String
    | Discard Notification


update : Msg -> Model -> Model
update message model =
    case message of
        AddError error ->
            model ++ [ Error error ]

        AddSuccess success ->
            model ++ [ Success success ]

        AddInfo info ->
            model ++ [ Info info ]

        Discard notification ->
            List.filter ((/=) notification) model


addError : Model -> String -> Model
addError notifications message =
    update (AddError message) notifications


addSuccess : Model -> String -> Model
addSuccess notifications message =
    update (AddSuccess message) notifications


addInfo : Model -> String -> Model
addInfo notifications message =
    update (AddInfo message) notifications


view : Model -> H.Html Msg
view notifications =
    H.div []
        (List.map viewNotification notifications)


viewNotification : Notification -> H.Html Msg
viewNotification notification =
    let
        ( message, status, icon ) =
            case notification of
                Error errorMessage ->
                    ( errorMessage, "error", "%PUBLIC_URL%/images/icons/24x24/message_alert_24_white.svg" )

                Success successMessage ->
                    ( successMessage, "success", "%PUBLIC_URL%/images/icons/24x24/message_valid_24_white.svg" )

                Info infoMessage ->
                    ( infoMessage, "", "%PUBLIC_URL%/images/icons/24x24/message_info_24_white.svg" )
    in
    H.div [ HA.class <| "notification closable " ++ status ]
        [ H.img [ HA.src icon ]
            []
        , H.text " "
        , H.span []
            [ H.text message ]
        , H.button
            [ HA.class "close"
            , HE.onClick <| Discard notification
            ]
            [ H.i [ HA.class "fas fa-times" ] []
            ]
        ]

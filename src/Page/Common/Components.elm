module Page.Common.Components exposing
    ( ButtonState(..)
    , Document
    , button
    , iconButton
    , onChange
    , onFileSelected
    , optgroup
    , shareButtons
    , submitButton
    , viewConnectNow
    )

import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode
import Json.Encode as Encode
import Route


type ButtonState
    = Disabled
    | Loading
    | NotLoading


type alias Document msg =
    { title : String
    , pageTitle : String
    , pageSubTitle : String
    , body : List (H.Html msg)
    }


submitButton : String -> ButtonState -> H.Html msg
submitButton label buttonState =
    button label buttonState Nothing


button : String -> ButtonState -> Maybe msg -> H.Html msg
button label buttonState maybeOnClick =
    H.button
        (loadingAttrs buttonState ++ onClickAttr maybeOnClick)
        (H.text label :: loadingIcon buttonState)


iconButton : String -> String -> ButtonState -> Maybe msg -> H.Html msg
iconButton label iconSrc buttonState maybeOnClick =
    let
        icon =
            H.img
                [ HA.src iconSrc
                ]
                []
    in
    H.button
        (loadingAttrs buttonState ++ onClickAttr maybeOnClick)
        ([ icon
         , H.text " "
         , H.text label
         ]
            ++ loadingIcon buttonState
        )


loadingAttrs : ButtonState -> List (H.Attribute msg)
loadingAttrs buttonState =
    case buttonState of
        Disabled ->
            [ HA.type_ "submit"
            , HA.class "button"
            , HA.disabled True
            ]

        Loading ->
            [ HA.type_ "submit"
            , HA.class "button button-loader"
            , HA.disabled True
            ]

        NotLoading ->
            [ HA.type_ "submit"
            , HA.class "button"
            ]


onClickAttr : Maybe msg -> List (H.Attribute msg)
onClickAttr maybeOnClick =
    maybeOnClick
        |> Maybe.map (\onClick -> [ HE.onClick onClick ])
        |> Maybe.withDefault []


loadingIcon : ButtonState -> List (H.Html msg)
loadingIcon buttonState =
    if buttonState == Loading then
        [ H.text " "
        , H.i [ HA.class "fas fa-spinner fa-spin" ] []
        ]

    else
        []



---- SHARE BUTTONS ----


shareButtons shareText shareUrl navigatorShare navigatorShareOnClick =
    let
        navigatorShareButton =
            if navigatorShare then
                [ H.li []
                    [ H.a
                        [ HE.onClick navigatorShareOnClick
                        , HA.href "#"
                        , HA.title "Partager la vidéo en utilisant une application"
                        ]
                        [ H.img [ HA.src "%PUBLIC_URL%/images/icons/32x32/app_32_purple.svg" ] [] ]
                    ]
                ]

            else
                []
    in
    H.ul [ HA.class "social" ]
        ([ H.li []
            [ H.a
                [ HA.href "https://www.facebook.com/sharer/sharer.php"
                , HA.title "Partager la vidéo par facebook"
                ]
                [ H.img [ HA.src "%PUBLIC_URL%/images/icons/32x32/facebook_32_purple.svg" ] [] ]
            ]
         , H.li []
            [ H.a
                [ HA.href <| "http://twitter.com/share?text=" ++ shareText
                , HA.title "Partager la vidéo par twitter"
                ]
                [ H.img [ HA.src "%PUBLIC_URL%/images/icons/32x32/twitter_32_purple.svg" ] [] ]
            ]
         , H.li []
            [ H.a
                [ HA.href <| "whatsapp://send?text=" ++ shareText ++ " : " ++ shareUrl
                , HA.property "data-action" (Encode.string "share/whatsapp/share")
                , HA.title "Partager la vidéo par whatsapp"
                ]
                [ H.img [ HA.src "%PUBLIC_URL%/images/icons/32x32/whatsapp_32_purple.svg" ] [] ]
            ]
         , H.li []
            [ H.a
                [ HA.href <| "mailto:?body=" ++ shareText ++ "&subject=" ++ shareText
                , HA.title "Partager la vidéo par email"
                ]
                [ H.img [ HA.src "%PUBLIC_URL%/images/icons/32x32/message_32_purple.svg" ] [] ]
            ]
         , H.li []
            [ H.a
                [ HA.href "https://www.tchap.gouv.fr/"
                , HA.title "Partager la vidéo par Tchap"
                ]
                [ H.img [ HA.src "%PUBLIC_URL%/images/icons/32x32/tchap_32_purple.svg" ] [] ]
            ]
         ]
            ++ navigatorShareButton
        )



---- FORMS AND EVENTS ----


onChange : (String -> msg) -> H.Attribute msg
onChange tagger =
    HE.on "change" (Decode.map tagger HE.targetValue)


optgroup : String -> List (H.Html msg) -> H.Html msg
optgroup label nodes =
    H.optgroup [ HA.property "label" <| Encode.string label ] nodes


viewConnectNow : String -> String -> H.Html msg
viewConnectNow label linkLabel =
    H.p []
        [ H.text label
        , H.a [ Route.href Route.Login ] [ H.text linkLabel ]
        ]


onFileSelected : msg -> H.Attribute msg
onFileSelected msg =
    HE.on "change" (Decode.succeed msg)

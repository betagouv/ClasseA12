module Page.Common.Components exposing
    ( ButtonState(..)
    , Document
    , button
    , onChange
    , onFileSelected
    , optgroup
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
    let
        loadingAttrs =
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

        onClickAttr =
            maybeOnClick
                |> Maybe.map (\onClick -> [ HE.onClick onClick ])
                |> Maybe.withDefault []
    in
    H.button
        (loadingAttrs ++ onClickAttr)
        [ if buttonState == Loading then
            H.i [ HA.class "fas fa-spinner fa-spin" ] []

          else
            H.text label
        ]



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

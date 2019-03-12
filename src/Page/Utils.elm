module Page.Utils exposing
    ( ButtonState(..)
    , Progress
    , button
    , emptyProgress
    , onChange
    , onFileSelected
    , optgroup
    , progressDecoder
    , submitButton
    , viewConnectNow
    )

import Data.Kinto
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Markdown
import Page.Common.Dates
import Route
import Time



---- BUTTONS ----


type ButtonState
    = Disabled
    | Loading
    | NotLoading


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
    H.div [ HA.class "section section-white" ]
        [ H.div [ HA.class "container" ]
            [ H.text label
            , H.a [ Route.href Route.Login ] [ H.text linkLabel ]
            ]
        ]


onFileSelected : msg -> H.Attribute msg
onFileSelected msg =
    HE.on "change" (Decode.succeed msg)



---- HTTP progress updates ----


type alias Progress =
    { percentage : Int
    , message : String
    }


emptyProgress : Progress
emptyProgress =
    { percentage = 0, message = "" }


progressDecoder =
    Decode.succeed Progress
        |> Pipeline.required "percentage" Decode.int
        |> Pipeline.required "message" Decode.string

module Page.Utils exposing
    ( Progress
    , emptyProgress
    , progressDecoder
    )

import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Route
import Time



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

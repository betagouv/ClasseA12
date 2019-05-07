module Page.Common.Progress exposing (Progress, decoder, empty)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline


type alias Progress =
    { percentage : Int
    , message : String
    }


empty : Progress
empty =
    { percentage = 0, message = "" }


decoder : Decode.Decoder Progress
decoder =
    Decode.succeed Progress
        |> Pipeline.required "percentage" Decode.int
        |> Pipeline.required "message" Decode.string

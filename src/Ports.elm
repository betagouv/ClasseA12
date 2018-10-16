port module Ports exposing (parseRSS, parsedVideoList)

import Json.Decode as Decode


port parseRSS : String -> Cmd msg


port parsedVideoList : (Decode.Value -> msg) -> Sub msg

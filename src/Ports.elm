port module Ports exposing (parseRSS, parsedVideoList, videoObjectUrl, videoSelected)

import Json.Decode as Decode


port parseRSS : String -> Cmd msg


port parsedVideoList : (Decode.Value -> msg) -> Sub msg


port videoSelected : String -> Cmd msg


port videoObjectUrl : (Decode.Value -> msg) -> Sub msg

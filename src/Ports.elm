port module Ports exposing (parseRSS, parsedVideoList, progressUpdate, submitVideo, videoObjectUrl, videoSelected, videoSubmitted)

import Json.Decode as Decode


port parseRSS :
    -- the xml string of the rss feed
    String -> Cmd msg


port parsedVideoList : (Decode.Value -> msg) -> Sub msg


port videoSelected :
    -- the file input id
    String -> Cmd msg


port videoObjectUrl : (Decode.Value -> msg) -> Sub msg


port submitVideo :
    -- (the file input id, the record ID on which to add the attachment file)
    ( String, String ) -> Cmd msg


port videoSubmitted : (Decode.Value -> msg) -> Sub msg


port progressUpdate : (Decode.Value -> msg) -> Sub msg

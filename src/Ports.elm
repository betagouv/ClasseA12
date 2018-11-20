port module Ports exposing
    ( SubmitVideoData
    , newURL
    , parseRSS
    , parsedVideoList
    , progressUpdate
    , submitVideo
    , videoObjectUrl
    , videoSelected
    , videoSubmitted
    )

import Json.Decode as Decode


port parseRSS :
    -- the xml string of the rss feed
    String -> Cmd msg


port parsedVideoList : (Decode.Value -> msg) -> Sub msg


port videoSelected :
    -- the file input id
    String -> Cmd msg


port videoObjectUrl : (Decode.Value -> msg) -> Sub msg


type alias SubmitVideoData =
    { nodeID : String
    , videoData : Decode.Value
    , login : String
    , password : String
    }


port submitVideo : SubmitVideoData -> Cmd msg


port videoSubmitted : (String -> msg) -> Sub msg


port progressUpdate : (Decode.Value -> msg) -> Sub msg


port newURL : String -> Cmd msg

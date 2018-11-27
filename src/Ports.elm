port module Ports exposing
    ( SubmitVideoData
    , logoutSession
    , newURL
    , progressUpdate
    , saveSession
    , submitVideo
    , videoObjectUrl
    , videoSelected
    , videoSubmitted
    )

import Json.Decode as Decode
import Json.Encode as Encode


port videoSelected :
    -- the file input id
    String -> Cmd msg


port videoObjectUrl : (Decode.Value -> msg) -> Sub msg


type alias SubmitVideoData =
    { nodeID : String
    , videoNodeID : String
    , videoData : Decode.Value
    , login : String
    , password : String
    }


port submitVideo : SubmitVideoData -> Cmd msg


port videoSubmitted : (String -> msg) -> Sub msg


port progressUpdate : (Decode.Value -> msg) -> Sub msg


port newURL :
    -- As we're using pushstate, we have to explicitely warn javascript (and analytics) of any url change
    String -> Cmd msg


port saveSession : Encode.Value -> Cmd msg


port logoutSession : () -> Cmd msg

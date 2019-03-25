port module Ports exposing
    ( SubmitAttachmentData
    , SubmitVideoData
    , attachmentSubmitted
    , logoutSession
    , navigatorShare
    , newURL
    , progressUpdate
    , saveUserInfo
    , saveUserToken
    , submitAttachment
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
    ( String, String ) -> Cmd msg


port saveUserToken : Encode.Value -> Cmd msg


port saveUserInfo : Encode.Value -> Cmd msg


port logoutSession : () -> Cmd msg


port navigatorShare : String -> Cmd msg


type alias SubmitAttachmentData =
    { nodeID : String
    , commentID : String
    , login : String
    , password : String
    }


port submitAttachment : SubmitAttachmentData -> Cmd msg


port attachmentSubmitted : (String -> msg) -> Sub msg

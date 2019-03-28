module Data.PeerTube exposing
    ( Account
    , Comment
    , RemoteData(..)
    , UserInfo
    , UserToken
    , Video
    , accountDecoder
    , commentDecoder
    , dataDecoder
    , encodeComment
    , encodeUserInfo
    , encodeUserToken
    , userInfoDecoder
    , userTokenDecoder
    , videoDecoder
    )

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode


type alias UserToken =
    { access_token : String
    , expires_in : Int
    , refresh_token : String
    , token_type : String
    }


type alias UserInfo =
    { username : String
    }


type alias Account =
    { name : String
    , displayName : String
    , description : String
    }


type alias Video =
    { previewPath : String
    , name : String
    , embedPath : String
    , uuid : String
    , description : String
    , account : Account
    }


type alias Comment =
    { id : Int
    , text : String
    , videoId : Int
    , createdAt : String
    , updatedAt : String
    , account : Account
    }


type RemoteData a
    = NotRequested
    | Requested
    | Received a
    | Failed String



---- DECODERS ----


dataDecoder : Decode.Decoder (List Video)
dataDecoder =
    Decode.field "data" videoListDecoder


videoListDecoder : Decode.Decoder (List Video)
videoListDecoder =
    Decode.list videoDecoder


accountDecoder : Decode.Decoder Account
accountDecoder =
    Decode.succeed Account
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "displayName" Decode.string
        |> Pipeline.optional "description" Decode.string ""


videoDecoder : Decode.Decoder Video
videoDecoder =
    Decode.succeed Video
        |> Pipeline.required "previewPath" Decode.string
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "embedPath" Decode.string
        |> Pipeline.required "uuid" Decode.string
        |> Pipeline.optional "description" Decode.string ""
        |> Pipeline.required "account" accountDecoder


userTokenDecoder : Decode.Decoder UserToken
userTokenDecoder =
    Decode.succeed UserToken
        |> Pipeline.required "access_token" Decode.string
        |> Pipeline.required "expires_in" Decode.int
        |> Pipeline.required "refresh_token" Decode.string
        |> Pipeline.required "token_type" Decode.string


userInfoDecoder : Decode.Decoder UserInfo
userInfoDecoder =
    Decode.succeed UserInfo
        |> Pipeline.required "username" Decode.string


commentDecoder : Decode.Decoder Comment
commentDecoder =
    Decode.succeed Comment
        |> Pipeline.required "id" Decode.int
        |> Pipeline.required "text" Decode.string
        |> Pipeline.required "videoId" Decode.int
        |> Pipeline.required "createdAt" Decode.string
        |> Pipeline.required "updatedAt" Decode.string
        |> Pipeline.required "account" accountDecoder



---- ENCODERS ----


encodeUserInfo : UserInfo -> Encode.Value
encodeUserInfo userInfo =
    Encode.object [ ( "username", Encode.string userInfo.username ) ]


encodeUserToken : UserToken -> Encode.Value
encodeUserToken userToken =
    Encode.object
        [ ( "access_token", Encode.string userToken.access_token )
        , ( "expires_in", Encode.int userToken.expires_in )
        , ( "refresh_token", Encode.string userToken.refresh_token )
        , ( "token_type", Encode.string userToken.token_type )
        ]


encodeComment : String -> Encode.Value
encodeComment text =
    Encode.object
        [ ( "text", Encode.string text ) ]

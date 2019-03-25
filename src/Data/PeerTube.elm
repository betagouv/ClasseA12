module Data.PeerTube exposing
    ( Account
    , RemoteData(..)
    , UserInfo
    , UserToken
    , Video
    , accountDecoder
    , dataDecoder
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
    { accessToken : String
    , expiresIn : Int
    , refreshToken : String
    , tokenType : String
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



---- ENCODERS ----


encodeUserInfo : UserInfo -> Encode.Value
encodeUserInfo userInfo =
    Encode.object [ ( "username", Encode.string userInfo.username ) ]


encodeUserToken : UserToken -> Encode.Value
encodeUserToken userToken =
    Encode.object
        [ ( "accessToken", Encode.string userToken.accessToken )
        , ( "expiresIn", Encode.int userToken.expiresIn )
        , ( "refreshToken", Encode.string userToken.refreshToken )
        , ( "tokenType", Encode.string userToken.tokenType )
        ]

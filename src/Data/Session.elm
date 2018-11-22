module Data.Session exposing
    ( LoginForm
    , Session
    , Video
    , VideoData(..)
    , decodeSessionData
    , decodeVideoList
    , emptyLoginForm
    , encodeData
    , encodeSessionData
    , videoDecoder
    )

import Json.Decode as Decode
import Json.Encode as Encode


type alias Session =
    { videoData : VideoData
    , loginForm : LoginForm
    }


type VideoData
    = Fetching
    | Received (List Video)
    | Error String


type alias Video =
    { description : String
    , link : String
    , player : String
    , pubDate : String
    , thumbnail : String
    , title : String
    }


videoDecoder : Decode.Decoder Video
videoDecoder =
    Decode.map6 Video
        (Decode.field "description" Decode.string)
        (Decode.field "link" Decode.string)
        (Decode.field "player" Decode.string)
        (Decode.field "pubDate" Decode.string)
        (Decode.field "thumbnail" Decode.string)
        (Decode.field "title" Decode.string)


decodeVideoList : Decode.Value -> Result Decode.Error (List Video)
decodeVideoList =
    Decode.decodeValue <|
        Decode.list videoDecoder


encodeData : Video -> Encode.Value
encodeData video =
    Encode.object
        [ ( "description", Encode.string video.description )
        , ( "link", Encode.string video.link )
        , ( "player", Encode.string video.player )
        , ( "pubDate", Encode.string video.pubDate )
        , ( "thumbnail", Encode.string video.thumbnail )
        , ( "title", Encode.string video.title )
        ]



-- Session Data --


type alias LoginForm =
    { username : String
    , password : String
    }


emptyLoginForm : LoginForm
emptyLoginForm =
    { username = ""
    , password = ""
    }


encodeSessionData : LoginForm -> Encode.Value
encodeSessionData loginForm =
    Encode.object
        [ ( "username", Encode.string loginForm.username )
        , ( "password", Encode.string loginForm.password )
        ]


decodeSessionData : Decode.Decoder LoginForm
decodeSessionData =
    Decode.map2
        LoginForm
        (Decode.field "username" Decode.string)
        (Decode.field "password" Decode.string)

module Data.Session exposing
    ( LoginForm
    , Session
    , decodeSessionData
    , emptyLoginForm
    , encodeSessionData
    )

import Data.Kinto
import Json.Decode as Decode
import Json.Encode as Encode
import Time


type alias Session =
    { videoData : Data.Kinto.VideoListData
    , loginForm : LoginForm
    , timezone : Time.Zone
    , version : String
    , kintoURL : String
    }


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

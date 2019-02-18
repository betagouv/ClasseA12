module Data.Session exposing
    ( Session
    , UserData
    , decodeUserData
    , emptyUserData
    , encodeUserData
    , isLoggedIn
    )

import Data.Kinto
import Json.Decode as Decode
import Json.Encode as Encode
import Time
import Url exposing (Url)


type alias Session =
    { videoData : Data.Kinto.VideoListData
    , userData : UserData
    , timezone : Time.Zone
    , version : String
    , kintoURL : String
    , timestamp : Time.Posix
    , navigatorShare : Bool
    , url : Url
    , prevUrl : Url
    }


type alias UserData =
    { username : String
    , password : String
    , profile : Maybe String
    }


emptyUserData : UserData
emptyUserData =
    { username = ""
    , password = ""
    , profile = Nothing
    }


isLoggedIn : UserData -> Bool
isLoggedIn userData =
    case userData.profile of
        Just profile ->
            userData /= emptyUserData

        Nothing ->
            False


encodeUserData : UserData -> Encode.Value
encodeUserData userData =
    Encode.object
        ([ ( "username", Encode.string userData.username )
         , ( "password", Encode.string userData.password )
         ]
            ++ (case userData.profile of
                    Just profile ->
                        [ ( "profile", Encode.string profile ) ]

                    Nothing ->
                        []
               )
        )


decodeUserData : Decode.Decoder UserData
decodeUserData =
    Decode.map3
        UserData
        (Decode.field "username" Decode.string)
        (Decode.field "password" Decode.string)
        (Decode.field "profile" (Decode.maybe Decode.string))

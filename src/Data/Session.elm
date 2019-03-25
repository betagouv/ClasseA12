module Data.Session exposing
    ( Session
    , UserData
    , decodeStaticFiles
    , decodeUserData
    , emptyStaticFiles
    , emptyUserData
    , encodeUserData
    , isLoggedIn
    )

import Data.Kinto
import Dict
import Json.Decode as Decode
import Json.Encode as Encode
import Time
import Url exposing (Url)


type alias Session =
    { userData : UserData
    , timezone : Time.Zone
    , version : String
    , kintoURL : String
    , peerTubeURL : String
    , navigatorShare : Bool
    , staticFiles : StaticFiles
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


type alias StaticFiles =
    { logo : String
    , logo_ca12 : String
    , autorisationCaptationImageMineur : String
    , autorisationCaptationImageMajeur : String
    }


emptyStaticFiles : StaticFiles
emptyStaticFiles =
    { logo = ""
    , logo_ca12 = ""
    , autorisationCaptationImageMineur = ""
    , autorisationCaptationImageMajeur = ""
    }


decodeStaticFiles : Decode.Decoder StaticFiles
decodeStaticFiles =
    Decode.map4
        StaticFiles
        (Decode.field "logo" Decode.string)
        (Decode.field "logo_ca12" Decode.string)
        (Decode.field "autorisationCaptationImageMineur" Decode.string)
        (Decode.field "autorisationCaptationImageMajeur" Decode.string)

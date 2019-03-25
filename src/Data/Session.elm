module Data.Session exposing
    ( Session
    , decodeStaticFiles
    , emptyStaticFiles
    , isLoggedIn
    )

import Data.PeerTube
import Dict
import Json.Decode as Decode
import Json.Encode as Encode
import Time
import Url exposing (Url)


type alias Session =
    { timezone : Time.Zone
    , version : String
    , kintoURL : String
    , peerTubeURL : String
    , navigatorShare : Bool
    , staticFiles : StaticFiles
    , url : Url
    , prevUrl : Url
    , userInfo : Maybe Data.PeerTube.UserInfo
    , userToken : Maybe Data.PeerTube.UserToken
    }


isLoggedIn : Maybe Data.PeerTube.UserInfo -> Bool
isLoggedIn maybeUserInfo =
    maybeUserInfo
        |> Maybe.map (always True)
        |> Maybe.withDefault False


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

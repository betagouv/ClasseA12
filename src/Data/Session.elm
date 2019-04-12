module Data.Session exposing
    ( Session
    , UserData
    , decodeStaticFiles
    , decodeUserData
    , emptyStaticFiles
    , emptyUserData
    , encodeUserData
    , isLoggedIn
    , isPeerTubeLoggedIn
    , userInfoDecoder
    )

import Data.PeerTube
import Dict
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Time
import Url exposing (Url)


type alias Session =
    { userData : UserData
    , timezone : Time.Zone
    , version : String
    , kintoURL : String
    , peerTubeURL : String
    , filesURL : String
    , navigatorShare : Bool
    , staticFiles : StaticFiles
    , url : Url
    , prevUrl : Url
    , userInfo : Maybe Data.PeerTube.UserInfo
    , userToken : Maybe Data.PeerTube.UserToken
    , search : String
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


isPeerTubeLoggedIn : Maybe Data.PeerTube.UserInfo -> Bool
isPeerTubeLoggedIn maybeUserInfo =
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


userInfoDecoder : Decode.Decoder Data.PeerTube.UserInfo
userInfoDecoder =
    Decode.succeed Data.PeerTube.UserInfo
        |> Pipeline.required "username" Decode.string
        |> Pipeline.required "channelID" Decode.int

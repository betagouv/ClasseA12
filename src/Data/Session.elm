module Data.Session exposing
    ( Msg(..)
    , Session
    , UserData
    , decodeStaticFiles
    , decodeUserData
    , emptyStaticFiles
    , emptyUserData
    , encodeUserData
    , interpretMsg
    , isLoggedIn
    , isPeerTubeLoggedIn
    , userInfoDecoder
    )

import Browser.Navigation as Nav
import Data.PeerTube
import Dict
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Ports
import Route
import Time
import Url exposing (Url)


type Msg
    = Login Data.PeerTube.UserToken Data.PeerTube.UserInfo
    | Logout


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


interpretMsg :
    ( { a | session : Session, navKey : Nav.Key }, Cmd msg, Maybe Msg )
    -> ( { a | session : Session, navKey : Nav.Key }, Cmd msg )
interpretMsg ( { session, navKey } as model, cmd, maybeMessage ) =
    case maybeMessage of
        Nothing ->
            ( model, cmd )

        Just message ->
            let
                ( updatedSession, sessionCmd ) =
                    case message of
                        Login userToken userInfo ->
                            ( { session
                                | userInfo = Just userInfo
                                , userToken = Just userToken
                              }
                            , Cmd.batch
                                [ Ports.saveUserInfo <| Data.PeerTube.encodeUserInfo userInfo
                                , Ports.saveUserToken <| Data.PeerTube.encodeUserToken userToken
                                , redirectToPrevUrl session navKey
                                ]
                            )

                        Logout ->
                            ( { session
                                | userInfo = Nothing
                                , userToken = Nothing
                                , userData = emptyUserData
                              }
                            , Cmd.batch
                                [ Ports.logoutSession ()
                                , Route.pushUrl navKey Route.Login
                                ]
                            )
            in
            ( { model | session = updatedSession }, Cmd.batch [ cmd, sessionCmd ] )


redirectToPrevUrl : Session -> Nav.Key -> Cmd msg
redirectToPrevUrl session navKey =
    let
        shouldRedirectToPrevPage =
            case Route.fromUrl session.prevUrl of
                Nothing ->
                    False

                Just Route.Login ->
                    False

                Just (Route.Activate _ _) ->
                    False

                Just Route.ResetPassword ->
                    False

                Just (Route.SetNewPassword _ _) ->
                    False

                _ ->
                    True
    in
    if session.prevUrl /= session.url && shouldRedirectToPrevPage then
        Nav.pushUrl navKey <| Url.toString session.prevUrl

    else
        Route.pushUrl navKey Route.Home

module Data.Session exposing
    ( Msg(..)
    , Session
    , interpretMsg
    , isLoggedIn
    , userInfoDecoder
    )

import Browser.Navigation as Nav
import Data.PeerTube
import Dict
import Http
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
    | RefreshToken Data.PeerTube.UserToken


type alias Session =
    { timezone : Time.Zone
    , version : String
    , peerTubeURL : String
    , filesURL : String
    , navigatorShare : Bool
    , url : Url
    , prevUrl : Url
    , userInfo : Maybe Data.PeerTube.UserInfo
    , userToken : Maybe Data.PeerTube.UserToken
    , search : String
    }


isLoggedIn : Maybe Data.PeerTube.UserInfo -> Bool
isLoggedIn maybeUserInfo =
    maybeUserInfo
        |> Maybe.map (always True)
        |> Maybe.withDefault False


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
                              }
                            , Cmd.batch
                                [ Ports.logoutSession ()
                                , Route.pushUrl navKey Route.Login
                                ]
                            )

                        RefreshToken userToken ->
                            ( { session
                                | userToken = Just userToken
                              }
                            , Ports.saveUserToken <| Data.PeerTube.encodeUserToken userToken
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

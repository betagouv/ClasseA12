module Request.KintoUserInfo exposing (getUserInfo)

import Data.Kinto
import Http
import HttpBuilder
import Json.Decode as Decode
import Kinto


userInfoDecoder : Decode.Decoder Data.Kinto.UserInfo
userInfoDecoder =
    Decode.field "user" Data.Kinto.userInfoDecoder


getUserInfo : String -> String -> String -> (Result Http.Error Data.Kinto.UserInfo -> msg) -> Cmd msg
getUserInfo serverURL username password message =
    let
        (credsHeader, credsValue) =
            Kinto.Basic username password
                |> Kinto.headersForAuth
    in
    HttpBuilder.get serverURL
        |> HttpBuilder.withHeader credsHeader credsValue
        |> HttpBuilder.withExpectJson userInfoDecoder
        |> HttpBuilder.send message

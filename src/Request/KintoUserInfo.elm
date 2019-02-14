module Request.KintoUserInfo exposing (getUserInfo)

import Data.Kinto
import Http
import HttpBuilder
import Json.Decode as Decode
import Kinto


getUserInfo : String -> String -> String -> (Result Http.Error Data.Kinto.UserInfo -> msg) -> Cmd msg
getUserInfo serverURL username password message =
    let
        ( credsHeader, credsValue ) =
            Kinto.Basic username password
                |> Kinto.headersForAuth

        accountURL =
            serverURL ++ "accounts/" ++ username
    in
    HttpBuilder.get accountURL
        |> HttpBuilder.withHeader credsHeader credsValue
        |> HttpBuilder.withExpectJson Data.Kinto.userInfoDataDecoder
        |> HttpBuilder.send message

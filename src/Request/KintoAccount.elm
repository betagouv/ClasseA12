module Request.KintoAccount exposing (PasswordReset, UserInfo, UserInfoData, activate, associateProfile, register, resetPassword)

import Data.Kinto
import Http
import HttpBuilder
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Kinto


type alias UserInfo =
    -- This is different than then Data.Kinto.UserInfo: it doesn't have a profile field yet.
    { id : String, password : String }


type alias UserInfoData =
    Data.Kinto.KintoData UserInfo


userInfoDecoder : Decode.Decoder UserInfo
userInfoDecoder =
    Decode.succeed UserInfo
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "password" Decode.string


userInfoDataDecoder : Decode.Decoder UserInfo
userInfoDataDecoder =
    Decode.field "data" userInfoDecoder


register : String -> String -> String -> (Result Http.Error UserInfo -> msg) -> Cmd msg
register serverURL email password message =
    let
        accountURL =
            serverURL ++ "accounts"

        encodedAccount =
            Encode.object
                [ ( "id", Encode.string email )
                , ( "password", Encode.string password )
                ]

        encodedData =
            Encode.object [ ( "data", encodedAccount ) ]
    in
    HttpBuilder.post accountURL
        |> HttpBuilder.withExpectJson userInfoDataDecoder
        |> HttpBuilder.withJsonBody encodedData
        |> HttpBuilder.send message


activate : String -> String -> String -> (Result Http.Error UserInfo -> msg) -> Cmd msg
activate serverURL email activationKey message =
    let
        accountURL =
            serverURL ++ "accounts/" ++ email ++ "/validate/" ++ activationKey
    in
    HttpBuilder.post accountURL
        |> HttpBuilder.withExpectJson userInfoDecoder
        |> HttpBuilder.send message


associateProfile : String -> String -> String -> String -> (Result Http.Error Data.Kinto.UserInfo -> msg) -> Cmd msg
associateProfile serverURL email password profileID message =
    let
        accountURL =
            serverURL ++ "accounts/" ++ email

        ( credsHeader, credsValue ) =
            Kinto.Basic email password
                |> Kinto.headersForAuth

        encodedUpdatedAccount =
            Encode.object
                [ ( "profile", Encode.string profileID )
                , ( "password", Encode.string password )
                ]

        encodedData =
            Encode.object [ ( "data", encodedUpdatedAccount ) ]
    in
    HttpBuilder.patch accountURL
        |> HttpBuilder.withHeader credsHeader credsValue
        |> HttpBuilder.withExpectJson Data.Kinto.userInfoDataDecoder
        |> HttpBuilder.withJsonBody encodedData
        |> HttpBuilder.send message



---- RESET PASSWORD ----


type alias PasswordReset =
    -- What we get back from a POST to `/accounts/<user email>/reset-password` is a confirmation message.
    { message : String }


passwordResetDecoder : Decode.Decoder PasswordReset
passwordResetDecoder =
    Decode.succeed PasswordReset
        |> Pipeline.required "message" Decode.string
        |> Decode.andThen
            -- Make sure the confirmation message we get back from the endpoint is the correct one.
            (\resp ->
                if resp.message == "A temporary reset password has been sent by mail" then
                    Decode.succeed resp

                else
                    Decode.fail resp.message
            )


resetPassword : String -> String -> (Result Http.Error PasswordReset -> msg) -> Cmd msg
resetPassword serverURL email message =
    let
        accountURL =
            serverURL ++ "accounts/" ++ email ++ "/reset-password"
    in
    HttpBuilder.post accountURL
        |> HttpBuilder.withExpectJson passwordResetDecoder
        |> HttpBuilder.send message

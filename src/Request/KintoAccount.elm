module Request.KintoAccount exposing (UserInfo, UserInfoData, register)

import Data.Kinto
import Http
import HttpBuilder
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Kinto



-- This is different than then Data.Kinto.UserInfo: it doesn't have a profile field yet.


type alias UserInfo =
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

module Page.Common.XHR exposing (Response(..), decoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline


type alias XHR =
    { status : Int
    , statusText : String
    , response : String
    , responseURL : String
    }


type Response
    = Success String
    | BadStatus Int String


decoder : Decode.Decoder Response
decoder =
    Decode.succeed XHR
        |> Pipeline.required "status" Decode.int
        |> Pipeline.required "statusText" Decode.string
        |> Pipeline.optional "response" Decode.string ""
        |> Pipeline.optional "responseURL" Decode.string ""
        |> Decode.andThen
            (\xhr ->
                if 200 <= xhr.status && xhr.status < 300 then
                    if xhr.response /= "" then
                        Decode.succeed <| Success xhr.response

                    else
                        Decode.succeed <| Success xhr.responseURL

                else
                    Decode.succeed <| BadStatus xhr.status xhr.statusText
            )

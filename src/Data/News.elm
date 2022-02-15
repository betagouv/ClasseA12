module Data.News exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Time


type alias Post =
    { id : String
    , createdAt : Time.Posix
    , title : String
    , author : String
    , image : String
    , excerpt : String
    , content : Maybe String
    }



---- DECODERS ----


postDecoder : Decode.Decoder Post
postDecoder =
    Decode.succeed Post
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "created-at" (Decode.int |> Decode.map Time.millisToPosix)
        |> Pipeline.required "title" Decode.string
        |> Pipeline.required "author" Decode.string
        |> Pipeline.required "image" Decode.string
        |> Pipeline.required "excerpt" Decode.string
        |> Pipeline.hardcoded Nothing

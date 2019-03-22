module Data.PeerTube exposing (Account, RemoteData(..), Video, accountDecoder, dataDecoder, videoDecoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline


type alias Account =
    { name : String
    , displayName : String
    , description : String
    }


type alias Video =
    { previewPath : String
    , name : String
    , embedPath : String
    , uuid : String
    , account : Account
    }


type RemoteData a
    = NotRequested
    | Requested
    | Received a
    | Failed String



---- DECODERS


dataDecoder : Decode.Decoder (List Video)
dataDecoder =
    Decode.field "data" videoListDecoder


videoListDecoder : Decode.Decoder (List Video)
videoListDecoder =
    Decode.list videoDecoder


accountDecoder : Decode.Decoder Account
accountDecoder =
    Decode.succeed Account
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "displayName" Decode.string
        |> Pipeline.optional "description" Decode.string ""


videoDecoder : Decode.Decoder Video
videoDecoder =
    Decode.succeed Video
        |> Pipeline.required "previewPath" Decode.string
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "embedPath" Decode.string
        |> Pipeline.required "uuid" Decode.string
        |> Pipeline.required "account" accountDecoder

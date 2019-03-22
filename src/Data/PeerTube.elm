module Data.PeerTube exposing (Account, Uuid, Video, dataDecoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline


type Uuid
    = Uuid String


type alias Account =
    { uuid : Uuid, displayName : String }


type alias Video =
    { previewPath : String, name : String, account : Account }



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
        |> Pipeline.required "uuid" (Decode.string |> Decode.map Uuid)
        |> Pipeline.required "displayName" Decode.string


videoDecoder : Decode.Decoder Video
videoDecoder =
    Decode.succeed Video
        |> Pipeline.required "previewPath" Decode.string
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "account" accountDecoder

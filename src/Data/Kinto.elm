module Data.Kinto exposing (KintoData(..), Video, decodeVideoList, emptyVideo, encodeData, videoDecoder)

import Json.Decode as Decode
import Json.Encode as Encode
import Kinto


type KintoData a
    = NotRequested
    | Requested
    | Received a
    | Failed Kinto.Error


type alias Video =
    { title : String
    , keywords : String
    , description : String
    }


emptyVideo =
    { description = ""
    , title = ""
    , keywords = ""
    }


videoDecoder : Decode.Decoder Video
videoDecoder =
    Decode.map3 Video
        (Decode.field "description" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "keywords" Decode.string)


decodeVideoList : Decode.Value -> Result Decode.Error (List Video)
decodeVideoList =
    Decode.decodeValue <|
        Decode.list videoDecoder


encodeData : Video -> Encode.Value
encodeData video =
    Encode.object
        [ ( "description", Encode.string video.description )
        , ( "title", Encode.string video.title )
        , ( "keywords", Encode.string video.keywords )
        ]

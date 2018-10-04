module Data.Session exposing (Session, Video, VideoData(..), decodeVideoList)

import Json.Decode as Decode


type alias Session =
    { videoData : VideoData
    }


type VideoData
    = Fetching
    | Received (List Video)
    | Error String


type alias Video =
    { description : String
    , link : String
    , player : String
    , pubDate : String
    , thumbnail : String
    , title : String
    }


videoDecoder : Decode.Decoder Video
videoDecoder =
    Decode.map6 Video
        (Decode.field "description" Decode.string)
        (Decode.field "link" Decode.string)
        (Decode.field "player" Decode.string)
        (Decode.field "pubDate" Decode.string)
        (Decode.field "thumbnail" Decode.string)
        (Decode.field "title" Decode.string)


decodeVideoList : Decode.Value -> Result Decode.Error (List Video)
decodeVideoList =
    Decode.decodeValue <|
        Decode.list videoDecoder

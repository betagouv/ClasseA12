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
    { url : String
    , thumbnail : String
    , title : String
    , author : String
    , date : String
    }


videoDecoder : Decode.Decoder Video
videoDecoder =
    Decode.succeed { url = "", thumbnail = "", title = "", author = "", date = "" }


decodeVideoList : Decode.Value -> Result Decode.Error (List Video)
decodeVideoList =
    Decode.decodeValue <|
        Decode.succeed []

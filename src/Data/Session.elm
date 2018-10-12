module Data.Session exposing (Session, Video, VideoData(..), decodeVideoList)

import Json.Decode as Decode
import Json.Encode as Encode
import Kinto


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



---- KINTO ----


encodeData : String -> String -> String -> String -> String -> String -> Encode.Value
encodeData description link player pubDate thumbnail title =
    Encode.object
        [ ( "description", Encode.string description )
        , ( "link", Encode.string link )
        , ( "player", Encode.string player )
        , ( "pubDate", Encode.string pubDate )
        , ( "thumbnail", Encode.string thumbnail )
        , ( "title", Encode.string title )
        ]


recordResource : Kinto.Resource Video
recordResource =
    Kinto.recordResource "classea12" "upcoming" videoDecoder


upcomingVideosClient : Kinto.Client
upcomingVideosClient =
    Kinto.client "https://kinto.agopian.info/v1/" (Kinto.Basic "classea12" "notasecret")

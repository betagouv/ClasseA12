module Request.KintoUpcoming exposing (submitVideo, getVideoList)

import Data.Kinto
import Kinto
import Request.Kinto exposing (client)


submitVideo : Data.Kinto.NewVideo -> String -> String -> (Result Kinto.Error Data.Kinto.Video -> msg) -> Cmd msg
submitVideo newVideo login password message =
    client login password
        |> Kinto.create recordResource (Data.Kinto.encodeVideoData newVideo)
        |> Kinto.send message


recordResource : Kinto.Resource Data.Kinto.Video
recordResource =
    Kinto.recordResource "classea12" "upcoming" Data.Kinto.videoDecoder

getVideoList : String -> String -> (Result Kinto.Error (Kinto.Pager Data.Kinto.Video) -> msg) -> Cmd msg
getVideoList login password message =
    client login password
        |> Kinto.getList recordResource
        |> Kinto.sort [ "-last_modified" ]
        |> Kinto.send message
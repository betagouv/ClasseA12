-- Published videos


module Request.KintoVideo exposing (getVideoList, publishVideo)

import Data.Kinto
import Kinto
import Request.Kinto exposing (client)


publishVideo : Data.Kinto.Video -> String -> String -> (Result Kinto.Error Data.Kinto.Video -> msg) -> Cmd msg
publishVideo video login password message =
    client login password
        |> Kinto.create recordResource (Data.Kinto.encodeVideoData video)
        |> Kinto.send message


recordResource : Kinto.Resource Data.Kinto.Video
recordResource =
    Kinto.recordResource "classea12" "videos" Data.Kinto.videoDecoder


getVideoList : String -> String -> (Result Kinto.Error (Kinto.Pager Data.Kinto.Video) -> msg) -> Cmd msg
getVideoList login password message =
    client login password
        |> Kinto.getList recordResource
        |> Kinto.sort [ "-last_modified" ]
        |> Kinto.send message

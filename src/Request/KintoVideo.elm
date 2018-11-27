-- Published videos


module Request.KintoVideo exposing (getVideoList, publishVideo)

import Data.Kinto
import Kinto
import Request.Kinto


publishVideo : Data.Kinto.Video -> Request.Kinto.AuthClient -> (Result Kinto.Error Data.Kinto.Video -> msg) -> Cmd msg
publishVideo video (Request.Kinto.AuthClient client) message =
    client
        |> Kinto.create recordResource (Data.Kinto.encodeVideoData video)
        |> Kinto.send message


recordResource : Kinto.Resource Data.Kinto.Video
recordResource =
    Kinto.recordResource "classea12" "videos" Data.Kinto.videoDecoder


getVideoList : Request.Kinto.AnonymousClient -> (Result Kinto.Error Data.Kinto.VideoList -> msg) -> Cmd msg
getVideoList (Request.Kinto.AnonymousClient client) message =
    client
        |> Kinto.getList recordResource
        |> Kinto.sort [ "-last_modified" ]
        |> Kinto.send message

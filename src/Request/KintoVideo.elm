-- Published videos


module Request.KintoVideo exposing (getVideo, getVideoList, publishVideo)

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


getVideoList : (Result Kinto.Error Data.Kinto.VideoList -> msg) -> Cmd msg
getVideoList message =
    let
        (Request.Kinto.AnonymousClient client) =
            Request.Kinto.anonymousClient
    in
    client
        |> Kinto.getList recordResource
        |> Kinto.sort [ "-creation_date" ]
        |> Kinto.send message

getVideo : String  -> (Result Kinto.Error Data.Kinto.Video -> msg) -> Cmd msg
getVideo videoID message =
    let
        (Request.Kinto.AnonymousClient client) =
            Request.Kinto.anonymousClient
    in
    client
        |> Kinto.get recordResource videoID
        |> Kinto.send message

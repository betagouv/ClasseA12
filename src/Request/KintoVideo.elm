-- Published videos


module Request.KintoVideo exposing (getVideo, getVideoList, getVideoListRequest, publishVideo)

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


getVideoList : String -> (Result Kinto.Error Data.Kinto.VideoList -> msg) -> Cmd msg
getVideoList serverURL message =
    getVideoListRequest serverURL
        |> Kinto.sort [ "-creation_date" ]
        |> Kinto.send message


getVideoListRequest : String -> Kinto.Request Data.Kinto.VideoList
getVideoListRequest serverURL =
    let
        (Request.Kinto.AnonymousClient client) =
            Request.Kinto.anonymousClient serverURL
    in
    client
        |> Kinto.getList recordResource


getVideo : String -> String -> (Result Kinto.Error Data.Kinto.Video -> msg) -> Cmd msg
getVideo serverURL videoID message =
    let
        (Request.Kinto.AnonymousClient client) =
            Request.Kinto.anonymousClient serverURL
    in
    client
        |> Kinto.get recordResource videoID
        |> Kinto.send message

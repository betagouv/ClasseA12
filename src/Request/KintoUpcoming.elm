-- Upcoming videos, not yet published


module Request.KintoUpcoming exposing (getVideoList, removeVideo, submitVideo)

import Data.Kinto
import Kinto
import Request.Kinto


submitVideo : Data.Kinto.NewVideo -> Request.Kinto.AuthClient -> (Result Kinto.Error Data.Kinto.Video -> msg) -> Cmd msg
submitVideo newVideo (Request.Kinto.AuthClient client) message =
    client
        |> Kinto.create recordResource (Data.Kinto.encodeNewVideoData newVideo)
        |> Kinto.send message


recordResource : Kinto.Resource Data.Kinto.Video
recordResource =
    Kinto.recordResource "classea12" "upcoming" Data.Kinto.videoDecoder


getVideoList : Request.Kinto.AuthClient -> (Result Kinto.Error Data.Kinto.VideoList -> msg) -> Cmd msg
getVideoList (Request.Kinto.AuthClient client) message =
    client
        |> Kinto.getList recordResource
        |> Kinto.sort [ "-creation_date" ]
        |> Kinto.send message


removeVideo : Data.Kinto.Video -> Request.Kinto.AuthClient -> (Result Kinto.Error Data.Kinto.DeletedRecord -> msg) -> Cmd msg
removeVideo video (Request.Kinto.AuthClient client) message =
    client
        |> Kinto.delete deletedRecordResource video.id
        |> Kinto.send message


deletedRecordResource : Kinto.Resource Data.Kinto.DeletedRecord
deletedRecordResource =
    Kinto.recordResource "classea12" "upcoming" Data.Kinto.deletedRecordDecoder

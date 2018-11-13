module Request.KintoUpcoming exposing (submitVideo)

import Data.Kinto
import Kinto
import Request.Kinto exposing (client)


submitVideo : Data.Kinto.Video -> String -> String -> (Result Kinto.Error Data.Kinto.Video -> msg) -> Cmd msg
submitVideo video login password message =
    client login password
        |> Kinto.create recordResource (Data.Kinto.encodeVideoData video)
        |> Kinto.send message


recordResource : Kinto.Resource Data.Kinto.Video
recordResource =
    Kinto.recordResource "classea12" "upcoming" Data.Kinto.videoDecoder

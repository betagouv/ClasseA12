module Request.KintoUpcoming exposing (submitVideo)

import Data.Session
import Kinto


submitVideo : Data.Session.Video -> (Result Kinto.Error Data.Session.Video -> msg) -> Cmd msg
submitVideo video message =
    client
        |> Kinto.create recordResource (Data.Session.encodeData video)
        |> Kinto.send message


recordResource : Kinto.Resource Data.Session.Video
recordResource =
    Kinto.recordResource "classea12" "upcoming" Data.Session.videoDecoder


client : Kinto.Client
client =
    Kinto.client "https://kinto.agopian.info/v1/" (Kinto.Basic "classea12" "notasecret")

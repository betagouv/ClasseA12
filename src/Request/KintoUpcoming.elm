module Request.KintoUpcoming exposing (submitVideo)

import Data.Kinto
import Kinto


submitVideo : Data.Kinto.Video -> (Result Kinto.Error Data.Kinto.Video -> msg) -> Cmd msg
submitVideo video message =
    client
        |> Kinto.create recordResource (Data.Kinto.encodeData video)
        |> Kinto.send message


recordResource : Kinto.Resource Data.Kinto.Video
recordResource =
    Kinto.recordResource "classea12" "upcoming" Data.Kinto.videoDecoder


client : Kinto.Client
client =
    Kinto.client "https://kinto.agopian.info/v1/" (Kinto.Basic "classea12" "notasecret")

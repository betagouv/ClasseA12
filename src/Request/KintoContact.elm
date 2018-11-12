module Request.KintoContact exposing (submitContact)

import Data.Kinto
import Kinto


submitContact : Data.Kinto.Contact -> (Result Kinto.Error Data.Kinto.Contact -> msg) -> Cmd msg
submitContact contact message =
    client
        |> Kinto.create recordResource (Data.Kinto.encodeContactData contact)
        |> Kinto.send message


recordResource : Kinto.Resource Data.Kinto.Contact
recordResource =
    Kinto.recordResource "classea12" "contacts" Data.Kinto.contactDecoder


client : Kinto.Client
client =
    Kinto.client "https://kinto.agopian.info/v1/" (Kinto.Basic "classea12" "notasecret")
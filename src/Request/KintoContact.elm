module Request.KintoContact exposing (submitContact)

import Data.Kinto
import Kinto


submitContact : Data.Kinto.Contact -> String -> (Result Kinto.Error Data.Kinto.Contact -> msg) -> Cmd msg
submitContact contact password message =
    client contact.email password
        |> Kinto.create recordResource (Data.Kinto.encodeContactData contact)
        |> Kinto.send message


recordResource : Kinto.Resource Data.Kinto.Contact
recordResource =
    Kinto.recordResource "classea12" "contacts" Data.Kinto.contactDecoder


client : String -> String -> Kinto.Client
client login password =
    Kinto.client "https://kinto.agopian.info/v1/" (Kinto.Basic login password)
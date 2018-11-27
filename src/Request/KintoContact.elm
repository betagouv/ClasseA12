module Request.KintoContact exposing (submitContact)

import Data.Kinto
import Kinto
import Request.Kinto


submitContact : Data.Kinto.Contact -> String -> (Result Kinto.Error Data.Kinto.Contact -> msg) -> Cmd msg
submitContact contact password message =
    let
        (Request.Kinto.AuthClient client) = Request.Kinto.authClient contact.email password
    in
        client
        |> Kinto.create recordResource (Data.Kinto.encodeContactData contact)
        |> Kinto.send message


recordResource : Kinto.Resource Data.Kinto.Contact
recordResource =
    Kinto.recordResource "classea12" "contacts" Data.Kinto.contactDecoder

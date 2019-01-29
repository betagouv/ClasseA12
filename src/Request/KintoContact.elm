module Request.KintoContact exposing (getContactList, submitContact)

import Data.Kinto
import Kinto
import Request.Kinto


submitContact : String -> Data.Kinto.Contact -> String -> (Result Kinto.Error Data.Kinto.Contact -> msg) -> Cmd msg
submitContact serverURL contact password message =
    let
        (Request.Kinto.AuthClient client) = Request.Kinto.authClient serverURL contact.email password
    in
        client
        |> Kinto.create recordResource (Data.Kinto.encodeContactData contact)
        |> Kinto.send message


recordResource : Kinto.Resource Data.Kinto.Contact
recordResource =
    Kinto.recordResource "classea12" "contacts" Data.Kinto.contactDecoder


getContactList : Request.Kinto.AuthClient -> (Result Kinto.Error Data.Kinto.ContactList -> msg) -> Cmd msg
getContactList (Request.Kinto.AuthClient client) message =
    client
        |> Kinto.getList recordResource
        |> Kinto.sort [ "-last_modified" ]
        |> Kinto.send message
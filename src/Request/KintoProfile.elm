module Request.KintoProfile exposing (getProfile, getProfileList, getProfileListRequest, submitProfile, updateProfile)

import Data.Kinto
import Kinto
import Request.Kinto


submitProfile : Request.Kinto.AuthClient -> Data.Kinto.Profile -> (Result Kinto.Error Data.Kinto.Profile -> msg) -> Cmd msg
submitProfile (Request.Kinto.AuthClient client) profile message =
    client
        |> Kinto.create recordResource (Data.Kinto.encodeProfileData profile)
        |> Kinto.send message


updateProfile : Request.Kinto.AuthClient -> Data.Kinto.Profile -> (Result Kinto.Error Data.Kinto.Profile -> msg) -> Cmd msg
updateProfile (Request.Kinto.AuthClient client) profile message =
    client
        |> Kinto.update recordResource profile.id (Data.Kinto.encodeProfileData profile)
        |> Kinto.send message


recordResource : Kinto.Resource Data.Kinto.Profile
recordResource =
    Kinto.recordResource "classea12" "profiles" Data.Kinto.profileDecoder


getProfile : String -> String -> (Result Kinto.Error Data.Kinto.Profile -> msg) -> Cmd msg
getProfile serverURL profileID message =
    let
        (Request.Kinto.AnonymousClient client) =
            Request.Kinto.anonymousClient serverURL
    in
    client
        |> Kinto.get recordResource profileID
        |> Kinto.send message


getProfileList : String -> List String -> (Result Kinto.Error Data.Kinto.ProfileList -> msg) -> Cmd msg
getProfileList serverURL profileIDs message =
    getProfileListRequest serverURL profileIDs
        |> Kinto.sort [ "last_modified" ]
        |> Kinto.send message


getProfileListRequest : String -> List String -> Kinto.Request Data.Kinto.ProfileList
getProfileListRequest serverURL profileIDs =
    let
        (Request.Kinto.AnonymousClient client) =
            Request.Kinto.anonymousClient serverURL
    in
    client
        |> Kinto.getList recordResource
        |> Kinto.filter (Kinto.IN "id" profileIDs)
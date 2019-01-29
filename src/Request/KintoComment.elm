module Request.KintoComment exposing (getCommentList, submitComment)

import Data.Kinto
import Kinto
import Request.Kinto


submitComment : Kinto.Client -> Data.Kinto.Comment -> (Result Kinto.Error Data.Kinto.Comment -> msg) -> Cmd msg
submitComment client comment message =
        client
        |> Kinto.create recordResource (Data.Kinto.encodeCommentData comment)
        |> Kinto.send message


recordResource : Kinto.Resource Data.Kinto.Comment
recordResource =
    Kinto.recordResource "classea12" "comments" Data.Kinto.commentDecoder


getCommentList : String -> String -> (Result Kinto.Error Data.Kinto.CommentList -> msg) -> Cmd msg
getCommentList serverURL videoID message =
    let
        (Request.Kinto.AnonymousClient client) =
            Request.Kinto.anonymousClient serverURL
    in
    client
        |> Kinto.getList recordResource
        |> Kinto.filter (Kinto.EQUAL "video" videoID)
        |> Kinto.sort [ "last_modified" ]
        |> Kinto.send message
module Request.KintoComment exposing (getCommentList, getCommentListRequest, getVideoCommentList, submitComment)

import Data.Kinto
import Kinto
import Request.Kinto


submitComment : Request.Kinto.AuthClient -> Data.Kinto.Comment -> (Result Kinto.Error Data.Kinto.Comment -> msg) -> Cmd msg
submitComment (Request.Kinto.AuthClient client) comment message =
    client
        |> Kinto.create recordResource (Data.Kinto.encodeCommentData comment)
        |> Kinto.send message


recordResource : Kinto.Resource Data.Kinto.Comment
recordResource =
    Kinto.recordResource "classea12" "comments" Data.Kinto.commentDecoder


getVideoCommentList : String -> String -> (Result Kinto.Error Data.Kinto.CommentList -> msg) -> Cmd msg
getVideoCommentList serverURL videoID message =
    getCommentListRequest serverURL
        |> Kinto.filter (Kinto.EQUAL "video" videoID)
        |> Kinto.sort [ "last_modified" ]
        |> Kinto.send message


getCommentList : String -> (Result Kinto.Error Data.Kinto.CommentList -> msg) -> Cmd msg
getCommentList serverURL message =
    getCommentListRequest serverURL
        |> Kinto.sort [ "last_modified" ]
        |> Kinto.send message


getCommentListRequest : String -> Kinto.Request Data.Kinto.CommentList
getCommentListRequest serverURL =
    let
        (Request.Kinto.AnonymousClient client) =
            Request.Kinto.anonymousClient serverURL
    in
    client
        |> Kinto.getList recordResource

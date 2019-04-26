module Request.Files exposing (getVideoAttachmentList)

import Http
import Json.Decode as Decode


getVideoAttachmentListRequest : String -> String -> Http.Request (List String)
getVideoAttachmentListRequest videoID serverURL =
    let
        url =
            serverURL ++ "/" ++ videoID
    in
    Http.get url (Decode.list Decode.string)


getVideoAttachmentList : String -> String -> (Result Http.Error (List String) -> msg) -> Cmd msg
getVideoAttachmentList videoID serverURL message =
    Http.send message (getVideoAttachmentListRequest videoID serverURL)

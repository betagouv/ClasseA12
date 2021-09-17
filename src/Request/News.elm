module Request.News exposing (getPostList)

import Data.News
import Json.Decode as Decode
import RemoteData exposing (WebData)
import RemoteData.Http


getPostList : (WebData (List Data.News.Post) -> msg) -> Cmd msg
getPostList message =
    let
        url =
            "/blog/index.json"
    in
    RemoteData.Http.get url message (Decode.list Data.News.postDecoder)

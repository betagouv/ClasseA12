module Request.News exposing (getPost, getPostList)

import Data.News
import Dict
import Http
import Json.Decode as Decode
import RemoteData exposing (WebData)
import Task



---- POST LIST ----


getPostList : (WebData (List Data.News.Post) -> msg) -> Cmd msg
getPostList message =
    getPostListTask
        |> Task.attempt (RemoteData.fromResult >> message)


getPostListTask : Task.Task Http.Error (List Data.News.Post)
getPostListTask =
    Http.get "/blog/index.json" (Decode.list Data.News.postDecoder)
        |> Http.toTask



---- POST DETAILS ----


findPost : String -> List Data.News.Post -> Task.Task Http.Error Data.News.Post
findPost postID postList =
    postList
        |> List.filter (\post -> post.id == postID)
        |> List.head
        |> (\maybePost ->
                case maybePost of
                    Just post ->
                        Task.succeed post

                    Nothing ->
                        Task.fail (error404 postID)
           )


getPostContent : Data.News.Post -> Task.Task Http.Error Data.News.Post
getPostContent post =
    Http.getString (blogPostURL post.id)
        |> Http.toTask
        |> Task.map
            (\postContent ->
                { post | content = Just postContent }
            )


getPost : String -> (WebData Data.News.Post -> msg) -> Cmd msg
getPost postID message =
    getPostListTask
        |> Task.andThen (findPost postID)
        |> Task.andThen getPostContent
        |> Task.attempt (RemoteData.fromResult >> message)



---- UTILS ----


blogPostURL : String -> String
blogPostURL postID =
    "/blog/" ++ postID ++ "/Post.md"


error404 : String -> Http.Error
error404 postID =
    Http.BadStatus
        { url = blogPostURL postID
        , status =
            { code = 404
            , message = "Article non trouvé"
            }
        , headers = Dict.fromList []
        , body = ""
        }

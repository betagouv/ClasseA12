module Request.KintoBatch exposing (CommentData, getCommentDataListTask)

import Data.Kinto
import Dict
import Http
import HttpBuilder
import Json.Decode as Decode
import Json.Encode as Encode
import Kinto
import Request.KintoComment
import Request.KintoProfile
import Request.KintoVideo
import Task
import Url.Builder



---- Get a list of comments associated with their contributor and video


type alias CommentData =
    { comment : Data.Kinto.Comment
    , contributor : Data.Kinto.Profile
    , video : Data.Kinto.Video
    }


getCommentDataListTask : String -> Task.Task Kinto.Error (List CommentData)
getCommentDataListTask serverURL =
    -- First get the list of comments
    getComments serverURL
        |> Task.map
            (\commentsPager ->
                -- Then build the list of contributor IDs and video IDs from those comments
                let
                    comments =
                        commentsPager.objects

                    ( profileIDs, videoIDs ) =
                        comments
                            -- Get a list of [(profileID_1, videoID_1), (profileID_2, videoID_2)...]
                            |> List.map (\comment -> ( comment.profile, comment.video ))
                            -- Transform that in a list of [[profileID_1, profileID_2,...]
                            --                             , [videoID_1, videoID_2,...]]
                            |> List.unzip
                in
                ( comments, profileIDs, videoIDs )
            )
        |> Task.andThen
            (\( comments, profileIDs, videoIDs ) ->
                -- Now get the profiles and videos corresponding to those IDs in a batch request
                getContributorsVideosBatch serverURL profileIDs videoIDs
                    |> Task.map
                        (\( contributorDict, videoDict ) ->
                            -- And finally build the CommentData list by
                            -- associating the comment with its contributor and video
                            comments
                                |> List.map
                                    (\comment ->
                                        let
                                            contributor =
                                                Dict.get comment.profile contributorDict
                                                    |> Maybe.withDefault Data.Kinto.emptyProfile

                                            video =
                                                Dict.get comment.video videoDict
                                                    |> Maybe.withDefault Data.Kinto.emptyVideo
                                        in
                                        { comment = comment, contributor = contributor, video = video }
                                    )
                        )
            )


getComments : String -> Task.Task Kinto.Error Data.Kinto.CommentList
getComments serverURL =
    Request.KintoComment.getCommentListRequest serverURL
        |> Kinto.sort [ "-last_modified" ]
        |> Kinto.toRequest
        |> Http.toTask
        |> Task.mapError Kinto.extractError


requestToPath : String -> Kinto.Request a -> String
requestToPath serverURL request =
    -- massage a Kinto request url so we can use it in the batch requests' `path` field
    let
        queryParams =
            request.queryParams
                |> List.map (\( key, value ) -> Url.Builder.string key value)

        url =
            request.url
                |> String.replace serverURL ""
    in
    Url.Builder.absolute [ url ] queryParams


toDict : List { a | id : String } -> Dict.Dict String { a | id : String }
toDict recordList =
    -- Change from a list of records to a Dict of record.id -> record.
    recordList
        |> List.map (\record -> ( record.id, record ))
        |> Dict.fromList


getContributorsVideosBatch :
    String
    -> List String
    -> List String
    -> Task.Task Kinto.Error ( Dict.Dict String Data.Kinto.Profile, Dict.Dict String Data.Kinto.Video )
getContributorsVideosBatch serverURL profileIDs videoIDs =
    -- Make a batch request for contributors (profiles) and videos: http://docs.kinto-storage.org/en/stable/api/1.x/batch.html
    let
        batchURL =
            serverURL ++ "batch"

        getContributorsPath =
            Request.KintoProfile.getProfileListRequest serverURL profileIDs
                |> requestToPath serverURL

        getVideosPath =
            Request.KintoVideo.getVideoListRequest serverURL
                |> Kinto.filter (Kinto.IN "id" videoIDs)
                |> requestToPath serverURL

        encodedRequests =
            Encode.object
                [ ( "defaults", Encode.object [ ( "method", Encode.string "GET" ) ] )
                , ( "requests"
                  , Encode.list Encode.object
                        [ [ ( "path", Encode.string getContributorsPath ) ]
                        , [ ( "path", Encode.string getVideosPath ) ]
                        ]
                  )
                ]

        batchResponseDecoder =
            Decode.map2 Tuple.pair
                (Decode.field "responses" (Decode.index 0 contributorListDecoder))
                (Decode.field "responses" (Decode.index 1 videoListDecoder))

        contributorListDecoder =
            Decode.at [ "body", "data" ] (Decode.list Data.Kinto.profileDecoder)
                |> Decode.map toDict

        videoListDecoder =
            Decode.at [ "body", "data" ] (Decode.list Data.Kinto.videoDecoder)
                |> Decode.map toDict
    in
    HttpBuilder.post batchURL
        |> HttpBuilder.withExpectJson batchResponseDecoder
        |> HttpBuilder.withJsonBody encodedRequests
        |> HttpBuilder.toRequest
        |> Http.toTask
        |> Task.mapError Kinto.extractError

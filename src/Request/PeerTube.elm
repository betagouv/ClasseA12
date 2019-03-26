module Request.PeerTube exposing
    ( getAccount
    , getUserInfo
    , getVideo
    , getVideoCommentList
    , getVideoList
    , login
    , submitComment
    , updateUserAccount
    )

import Data.PeerTube
    exposing
        ( Account
        , Comment
        , UserInfo
        , UserToken
        , Video
        , accountDecoder
        , commentDecoder
        , dataDecoder
        , userInfoDecoder
        , userTokenDecoder
        , videoDecoder
        )
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Url


type alias Request a =
    { method : String
    , headers : List Http.Header
    , url : String
    , body : Http.Body
    , expect : Http.Expect a
    , timeout : Maybe Float
    , withCredentials : Bool
    }


videoListRequest : String -> Http.Request (List Video)
videoListRequest serverURL =
    let
        url =
            serverURL ++ "/video-channels/vincent_channel/videos"
    in
    Http.get url dataDecoder


getVideoList : String -> (Result Http.Error (List Video) -> msg) -> Cmd msg
getVideoList serverURL message =
    Http.send message (videoListRequest serverURL)


videoRequest : String -> String -> Http.Request Video
videoRequest videoID serverURL =
    let
        url =
            serverURL ++ "/videos/" ++ videoID
    in
    Http.get url videoDecoder


getVideo : String -> String -> (Result Http.Error Video -> msg) -> Cmd msg
getVideo videoID serverURL message =
    Http.send message (videoRequest videoID serverURL)


accountRequest : String -> String -> Http.Request Account
accountRequest accountName serverURL =
    let
        url =
            serverURL ++ "/accounts/" ++ accountName
    in
    Http.get url accountDecoder


getAccount : String -> String -> (Result Http.Error Account -> msg) -> Cmd msg
getAccount accountName serverURL message =
    Http.send message (accountRequest accountName serverURL)


loginRequest : String -> String -> String -> Http.Request UserToken
loginRequest username password serverURL =
    let
        url =
            serverURL ++ "/users/token"

        data =
            [ ( "username", username |> Url.percentEncode )
            , ( "password", password |> Url.percentEncode )
            , ( "client_id", "d2g8qdmcmc4gxiloss44murer3egmteo" )
            , ( "client_secret", "1IZJ6knBPJb7NJXhcH6jBDS15m6EXi4u" )
            , ( "grant_type", "password" )
            , ( "response_type", "code" )
            , ( "scope", "upload" )
            ]

        body =
            data
                |> List.map (\( key, val ) -> key ++ "=" ++ val)
                |> String.join "&"
                |> Http.stringBody "application/x-www-form-urlencoded"
    in
    Http.post url body userTokenDecoder


login : String -> String -> String -> (Result Http.Error UserToken -> msg) -> Cmd msg
login username password serverURL message =
    Http.send message (loginRequest username password serverURL)


getUserInfoRequest : String -> String -> Http.Request UserInfo
getUserInfoRequest accessToken serverURL =
    let
        url =
            serverURL ++ "/users/me"

        request : Request UserInfo
        request =
            { method = "GET"
            , headers = []
            , url = url
            , body = Http.emptyBody
            , expect = Http.expectJson userInfoDecoder
            , timeout = Nothing
            , withCredentials = False
            }
    in
    request
        |> withHeader "Authorization" ("Bearer " ++ accessToken)
        |> Http.request


getUserInfo : String -> String -> (Result Http.Error UserInfo -> msg) -> Cmd msg
getUserInfo accessToken serverURL message =
    Http.send message (getUserInfoRequest accessToken serverURL)


updateUserAccountRequest : String -> String -> String -> String -> Http.Request Account
updateUserAccountRequest displayName description accessToken serverURL =
    let
        url =
            serverURL ++ "/users/me"

        body =
            Encode.object
                [ ( "displayName", Encode.string displayName )
                , ( "description", Encode.string description )
                ]
                |> Http.jsonBody

        request : Request Account
        request =
            { method = "PUT"
            , headers = []
            , url = url
            , body = body
            , expect = Http.expectJson accountDecoder
            , timeout = Nothing
            , withCredentials = False
            }
    in
    request
        |> withHeader "Authorization" ("Bearer " ++ accessToken)
        |> Http.request


updateUserAccount : String -> String -> String -> String -> (Result Http.Error Account -> msg) -> Cmd msg
updateUserAccount displayName description accessToken serverURL message =
    Http.send message (updateUserAccountRequest displayName description accessToken serverURL)


withHeader : String -> String -> Request a -> Request a
withHeader headerName headerValue request =
    let
        header =
            Http.header headerName headerValue
    in
    { request | headers = header :: request.headers }


videoCommentListRequest : String -> String -> Http.Request (List Comment)
videoCommentListRequest videoID serverURL =
    let
        url =
            serverURL ++ "/videos/" ++ videoID ++ "/comment-threads"
    in
    Http.get url (Decode.list commentDecoder)


getVideoCommentList : String -> String -> (Result Http.Error (List Comment) -> msg) -> Cmd msg
getVideoCommentList videoID serverURL message =
    Http.send message (videoCommentListRequest videoID serverURL)


submitCommentRequest : String -> String -> String -> String -> Http.Request Comment
submitCommentRequest comment videoID accessToken serverURL =
    let
        url =
            serverURL ++ "/videos/" ++ videoID ++ "/comment-threads"

        body =
            Encode.object
                [ ( "text", Encode.string comment )
                ]
                |> Http.jsonBody

        request : Request Comment
        request =
            { method = "POST"
            , headers = []
            , url = url
            , body = body
            , expect = Http.expectJson commentDecoder
            , timeout = Nothing
            , withCredentials = False
            }
    in
    request
        |> withHeader "Authorization" ("Bearer " ++ accessToken)
        |> Http.request


submitComment : String -> String -> String -> String -> (Result Http.Error Comment -> msg) -> Cmd msg
submitComment comment videoID accessToken serverURL message =
    Http.send message (submitCommentRequest comment videoID accessToken serverURL)
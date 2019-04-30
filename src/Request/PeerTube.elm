module Request.PeerTube exposing
    ( activate
    , askPasswordReset
    , changePassword
    , getAccount
    , getBlacklistedVideoList
    , getRecentVideoList
    , getUserInfo
    , getVideo
    , getVideoCommentList
    , getVideoList
    , is401
    , login
    , publishVideo
    , register
    , submitComment
    , updateUserAccount
    )

import Data.PeerTube
    exposing
        ( Account
        , BlacklistedVideo
        , Comment
        , UserInfo
        , UserToken
        , Video
        , accountDecoder
        , blacklistedVideoDecoder
        , commentDecoder
        , commentListDecoder
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



---- VIDEOS ----


recentVideoListRequest : String -> Http.Request (List Video)
recentVideoListRequest serverURL =
    let
        url =
            serverURL ++ "/api/v1/search/videos?start=0&count=8&categoryOneOf=13&sort=-publishedAt"
    in
    Http.get url dataDecoder


getRecentVideoList : String -> (Result Http.Error (List Video) -> msg) -> Cmd msg
getRecentVideoList serverURL message =
    Http.send message (recentVideoListRequest serverURL)


videoListRequest : String -> String -> Http.Request (List Video)
videoListRequest tag serverURL =
    let
        url =
            serverURL ++ "/api/v1/search/videos?start=0&count=8&categoryOneOf=13&tagsOneOf=" ++ tag
    in
    Http.get url dataDecoder


getVideoList : String -> String -> (Result Http.Error (List Video) -> msg) -> Cmd msg
getVideoList tag serverURL message =
    Http.send message (videoListRequest tag serverURL)


videoRequest : String -> Maybe String -> String -> Http.Request Video
videoRequest videoID maybeAccessToken serverURL =
    let
        url =
            serverURL ++ "/api/v1/videos/" ++ videoID

        request : Request Video
        request =
            { method = "GET"
            , headers = []
            , url = url
            , body = Http.emptyBody
            , expect = Http.expectJson videoDecoder
            , timeout = Nothing
            , withCredentials = False
            }

        maybeAuthedRequest =
            case maybeAccessToken of
                Just accessToken ->
                    request
                        |> withHeader "Authorization" ("Bearer " ++ accessToken)

                Nothing ->
                    request
    in
    Http.request maybeAuthedRequest


getVideo : String -> Maybe String -> String -> (Result Http.Error Video -> msg) -> Cmd msg
getVideo videoID maybeAccessToken serverURL message =
    Http.send message (videoRequest videoID maybeAccessToken serverURL)


blacklistedVideoListRequest : String -> String -> Http.Request (List BlacklistedVideo)
blacklistedVideoListRequest accessToken serverURL =
    let
        url =
            serverURL ++ "/api/v1/videos/blacklist"

        request : Http.Request (List BlacklistedVideo)
        request =
            { method = "GET"
            , headers = []
            , url = url
            , body = Http.emptyBody
            , expect = Http.expectJson (Decode.field "data" <| Decode.list blacklistedVideoDecoder)
            , timeout = Nothing
            , withCredentials = False
            }
                |> withHeader "Authorization" ("Bearer " ++ accessToken)
                |> Http.request
    in
    request


getBlacklistedVideoList : String -> String -> (Result Http.Error (List BlacklistedVideo) -> msg) -> Cmd msg
getBlacklistedVideoList accessToken serverURL message =
    Http.send message (blacklistedVideoListRequest accessToken serverURL)


publishVideoRequest : BlacklistedVideo -> String -> String -> Http.Request String
publishVideoRequest blacklistedVideo accessToken serverURL =
    let
        url =
            serverURL ++ "/api/v1/videos/" ++ String.fromInt blacklistedVideo.video.id ++ "/blacklist"

        request : Http.Request String
        request =
            { method = "DELETE"
            , headers = []
            , url = url
            , body = Http.emptyBody
            , expect = Http.expectString
            , timeout = Nothing
            , withCredentials = False
            }
                |> withHeader "Authorization" ("Bearer " ++ accessToken)
                |> Http.request
    in
    request


publishVideo : BlacklistedVideo -> String -> String -> (Result Http.Error String -> msg) -> Cmd msg
publishVideo blacklistedVideo accessToken serverURL message =
    Http.send message (publishVideoRequest blacklistedVideo accessToken serverURL)



---- COMMENTS ----


videoCommentListRequest : String -> String -> Http.Request (List Comment)
videoCommentListRequest videoID serverURL =
    let
        url =
            serverURL ++ "/api/v1/videos/" ++ videoID ++ "/comment-threads"
    in
    Http.get url commentListDecoder


getVideoCommentList : String -> String -> (Result Http.Error (List Comment) -> msg) -> Cmd msg
getVideoCommentList videoID serverURL message =
    Http.send message (videoCommentListRequest videoID serverURL)


submitCommentRequest : String -> String -> String -> String -> Http.Request Comment
submitCommentRequest comment videoID access_token serverURL =
    let
        url =
            serverURL ++ "/api/v1/videos/" ++ videoID ++ "/comment-threads"

        body =
            Encode.object
                [ ( "text", Encode.string comment )
                ]
                |> Http.jsonBody

        decoder =
            Decode.field "comment" commentDecoder

        request : Http.Request Comment
        request =
            { method = "POST"
            , headers = []
            , url = url
            , body = body
            , expect = Http.expectJson decoder
            , timeout = Nothing
            , withCredentials = False
            }
                |> withHeader "Authorization" ("Bearer " ++ access_token)
                |> Http.request
    in
    request


submitComment : String -> String -> String -> String -> (Result Http.Error Comment -> msg) -> Cmd msg
submitComment comment videoID access_token serverURL message =
    Http.send message (submitCommentRequest comment videoID access_token serverURL)



---- USER AND ACCOUNT ----


registerRequest : String -> String -> String -> String -> Http.Request String
registerRequest username email password serverURL =
    let
        url =
            serverURL ++ "/api/v1/users/register"

        body =
            [ ( "username", username |> Encode.string )
            , ( "email", email |> Encode.string )
            , ( "password", password |> Encode.string )
            ]
                |> Encode.object
                |> Http.jsonBody

        request : Http.Request String
        request =
            { method = "POST"
            , headers = []
            , url = url
            , body = body
            , expect = Http.expectString
            , timeout = Nothing
            , withCredentials = False
            }
                |> Http.request
    in
    request


register : String -> String -> String -> String -> (Result Http.Error String -> msg) -> Cmd msg
register username email password serverURL message =
    Http.send message (registerRequest username email password serverURL)


activateRequest : String -> String -> String -> Http.Request String
activateRequest userID verificationString serverURL =
    let
        url =
            serverURL ++ "/api/v1/users/" ++ userID ++ "/verify-email"

        body =
            [ ( "verificationString", verificationString |> Encode.string ) ]
                |> Encode.object
                |> Http.jsonBody

        request : Http.Request String
        request =
            { method = "POST"
            , headers = []
            , url = url
            , body = body
            , expect = Http.expectString
            , timeout = Nothing
            , withCredentials = False
            }
                |> Http.request
    in
    request


activate : String -> String -> String -> (Result Http.Error String -> msg) -> Cmd msg
activate userID verificationString serverURL message =
    Http.send message (activateRequest userID verificationString serverURL)


askPasswordResetRequest : String -> String -> Http.Request String
askPasswordResetRequest email serverURL =
    let
        url =
            serverURL ++ "/api/v1/users/ask-reset-password"

        body =
            [ ( "email", email |> Encode.string ) ]
                |> Encode.object
                |> Http.jsonBody

        request : Http.Request String
        request =
            { method = "POST"
            , headers = []
            , url = url
            , body = body
            , expect = Http.expectString
            , timeout = Nothing
            , withCredentials = False
            }
                |> Http.request
    in
    request


askPasswordReset : String -> String -> (Result Http.Error String -> msg) -> Cmd msg
askPasswordReset email serverURL message =
    Http.send message (askPasswordResetRequest email serverURL)


changePasswordRequest : String -> String -> String -> String -> Http.Request String
changePasswordRequest userID verificationString password serverURL =
    let
        url =
            serverURL ++ "/api/v1/users/" ++ userID ++ "/reset-password"

        body =
            [ ( "verificationString", verificationString |> Encode.string )
            , ( "password", password |> Encode.string )
            ]
                |> Encode.object
                |> Http.jsonBody

        request : Http.Request String
        request =
            { method = "POST"
            , headers = []
            , url = url
            , body = body
            , expect = Http.expectString
            , timeout = Nothing
            , withCredentials = False
            }
                |> Http.request
    in
    request


changePassword : String -> String -> String -> String -> (Result Http.Error String -> msg) -> Cmd msg
changePassword userID verificationString password serverURL message =
    Http.send message (changePasswordRequest userID verificationString password serverURL)


accountRequest : String -> String -> Http.Request Account
accountRequest accountName serverURL =
    let
        url =
            serverURL ++ "/api/v1/accounts/" ++ accountName
    in
    Http.get url accountDecoder


getAccount : String -> String -> (Result Http.Error Account -> msg) -> Cmd msg
getAccount accountName serverURL message =
    Http.send message (accountRequest accountName serverURL)


loginRequest : String -> String -> String -> Http.Request UserToken
loginRequest username password serverURL =
    let
        url =
            serverURL ++ "/api/v1/users/token"

        data =
            [ ( "username", username |> Url.percentEncode )
            , ( "password", password |> Url.percentEncode )
            , ( "client_id", "i81pd4hxi635mvrbtayp2vikpvkvay9p" )
            , ( "client_secret", "8Ajuy56iRCW95ZFEwF1yAYzpFbQ2JnRS" )
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
getUserInfoRequest access_token serverURL =
    let
        url =
            serverURL ++ "/api/v1/users/me"

        request : Http.Request UserInfo
        request =
            { method = "GET"
            , headers = []
            , url = url
            , body = Http.emptyBody
            , expect = Http.expectJson userInfoDecoder
            , timeout = Nothing
            , withCredentials = False
            }
                |> withHeader "Authorization" ("Bearer " ++ access_token)
                |> Http.request
    in
    request


getUserInfo : String -> String -> (Result Http.Error UserInfo -> msg) -> Cmd msg
getUserInfo access_token serverURL message =
    Http.send message (getUserInfoRequest access_token serverURL)


updateUserAccountRequest : String -> String -> String -> String -> Http.Request Account
updateUserAccountRequest displayName description access_token serverURL =
    let
        url =
            serverURL ++ "/api/v1/users/me"

        body =
            Encode.object
                [ ( "displayName", Encode.string displayName )
                , ( "description", Encode.string description )
                ]
                |> Http.jsonBody

        account : Data.PeerTube.Account
        account =
            { name = ""
            , displayName = displayName
            , description = description
            }

        request : Http.Request Account
        request =
            { method = "PUT"
            , headers = []
            , url = url
            , body = body
            , expect = Http.expectStringResponse (\_ -> Ok account)
            , timeout = Nothing
            , withCredentials = False
            }
                |> withHeader "Authorization" ("Bearer " ++ access_token)
                |> Http.request
    in
    request


updateUserAccount : String -> String -> String -> String -> (Result Http.Error Account -> msg) -> Cmd msg
updateUserAccount displayName description access_token serverURL message =
    Http.send message (updateUserAccountRequest displayName description access_token serverURL)



---- UTILS ----


withHeader : String -> String -> Request a -> Request a
withHeader headerName headerValue request =
    let
        header =
            Http.header headerName headerValue
    in
    { request | headers = header :: request.headers }


is401 : Http.Error -> Bool
is401 error =
    case error of
        Http.BadStatus response ->
            response.status.code == 401

        _ ->
            False

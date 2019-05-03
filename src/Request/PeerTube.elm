module Request.PeerTube exposing
    ( VideoListParams
    , activate
    , askPasswordReset
    , changePassword
    , emptyVideoListParams
    , getAccount
    , getBlacklistedVideoList
    , getUserInfo
    , getVideo
    , getVideoCommentList
    , getVideoList
    , is401
    , loadMoreVideos
    , login
    , publishVideo
    , register
    , submitComment
    , updateUserAccount
    , urlFromVideoListParams
    , withKeyword
    , withKeywords
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
        , commentListDecoder
        , dataDecoder
        , userInfoDecoder
        , userTokenDecoder
        , videoDecoder
        )
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Task
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


type alias VideoListParams =
    { keywords : List String
    , count : Int
    , offset : Int
    }


emptyVideoListParams : VideoListParams
emptyVideoListParams =
    { keywords = []
    , count = 8
    , offset = 0
    }


withKeyword : String -> VideoListParams -> VideoListParams
withKeyword keyword ({ keywords } as videoListParams) =
    { videoListParams | keywords = keyword :: keywords }


withKeywords : List String -> VideoListParams -> VideoListParams
withKeywords keywords videoListParams =
    keywords
        |> List.foldl withKeyword videoListParams


loadMoreVideos : VideoListParams -> VideoListParams
loadMoreVideos ({ offset, count } as videoListParams) =
    { videoListParams | offset = offset + count }


urlFromVideoListParams : VideoListParams -> String -> String
urlFromVideoListParams { keywords, count, offset } serverURL =
    let
        url =
            serverURL
                ++ "/api/v1/search/videos?start="
                ++ String.fromInt offset
                ++ "&count="
                ++ String.fromInt count
                ++ "&categoryOneOf=13&sort=-publishedAt"
    in
    if keywords /= [] then
        keywords
            |> String.join "&tagsAllOf="
            |> (++) "&tagsAllOf="
            |> (++) url

    else
        url


videoListRequest : VideoListParams -> String -> Http.Request (List Video)
videoListRequest videoListParams serverURL =
    Http.get (urlFromVideoListParams videoListParams serverURL) dataDecoder


getVideoList : VideoListParams -> String -> (Result Http.Error (List Video) -> msg) -> Cmd msg
getVideoList videoListParams serverURL message =
    Http.send message (videoListRequest videoListParams serverURL)


videoRequest : String -> String -> Request Video
videoRequest videoID serverURL =
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
    in
    request


anonymousVideoRequest : String -> String -> Http.Request Video
anonymousVideoRequest videoID serverURL =
    videoRequest videoID serverURL
        |> Http.request


authVideoRequest : String -> String -> String -> Http.Request Video
authVideoRequest videoID access_token serverURL =
    videoRequest videoID serverURL
        |> withHeader "Authorization" ("Bearer " ++ access_token)
        |> Http.request


getVideo : String -> Maybe UserToken -> String -> (Result Http.Error Video -> msg) -> Cmd msg
getVideo videoID maybeUserToken serverURL message =
    case maybeUserToken of
        Just userToken ->
            authVideoRequest videoID
                |> authRequestWrapper userToken serverURL
                |> Task.attempt message

        Nothing ->
            Http.send message (anonymousVideoRequest videoID serverURL)


blacklistedVideoListRequest : String -> String -> Http.Request (List Video)
blacklistedVideoListRequest access_token serverURL =
    let
        url =
            serverURL ++ "/api/v1/videos/blacklist"

        request : Http.Request (List Video)
        request =
            { method = "GET"
            , headers = []
            , url = url
            , body = Http.emptyBody
            , expect = Http.expectJson (Decode.field "data" <| Decode.list (Decode.field "video" videoDecoder))
            , timeout = Nothing
            , withCredentials = False
            }
                |> withHeader "Authorization" ("Bearer " ++ access_token)
                |> Http.request
    in
    request


getBlacklistedVideoList : UserToken -> String -> (Result Http.Error (List Video) -> msg) -> Cmd msg
getBlacklistedVideoList userToken serverURL message =
    blacklistedVideoListRequest
        |> authRequestWrapper userToken serverURL
        |> Task.attempt message


publishVideoRequest : Video -> String -> String -> Http.Request String
publishVideoRequest video access_token serverURL =
    let
        url =
            serverURL ++ "/api/v1/videos/" ++ String.fromInt video.id ++ "/blacklist"

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
                |> withHeader "Authorization" ("Bearer " ++ access_token)
                |> Http.request
    in
    request


publishVideo : Video -> UserToken -> String -> (Result Http.Error String -> msg) -> Cmd msg
publishVideo video userToken serverURL message =
    publishVideoRequest video
        |> authRequestWrapper userToken serverURL
        |> Task.attempt message



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


submitComment : String -> String -> UserToken -> String -> (Result Http.Error Comment -> msg) -> Cmd msg
submitComment comment videoID userToken serverURL message =
    submitCommentRequest comment videoID
        |> authRequestWrapper userToken serverURL
        |> Task.attempt message



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


type alias Client =
    { client_id : String
    , client_secret : String
    }


clientDecoder : Decode.Decoder Client
clientDecoder =
    Decode.succeed Client
        |> Pipeline.required "client_id" Decode.string
        |> Pipeline.required "client_secret" Decode.string


clientRequest : String -> Http.Request Client
clientRequest serverURL =
    let
        url =
            serverURL ++ "/api/v1/oauth-clients/local"
    in
    Http.get url clientDecoder


loginRequest : String -> String -> String -> String -> String -> Http.Request UserToken
loginRequest client_id client_secret username password serverURL =
    let
        url =
            serverURL ++ "/api/v1/users/token"

        data =
            [ ( "username", username |> Url.percentEncode )
            , ( "password", password |> Url.percentEncode )
            , ( "client_id", client_id )
            , ( "client_secret", client_secret )
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
    Http.toTask (clientRequest serverURL)
        |> Task.andThen
            (\{ client_id, client_secret } ->
                Http.toTask (loginRequest client_id client_secret username password serverURL)
            )
        |> Task.attempt message


refreshTokenRequest : String -> String -> String -> String -> Http.Request UserToken
refreshTokenRequest client_id client_secret refresh_token serverURL =
    let
        url =
            serverURL ++ "/api/v1/users/token"

        data =
            [ ( "refresh_token", refresh_token )
            , ( "client_id", client_id )
            , ( "client_secret", client_secret )
            , ( "grant_type", "refresh_token" )
            , ( "response_type", "code" )
            ]

        body =
            data
                |> List.map (\( key, val ) -> key ++ "=" ++ val)
                |> String.join "&"
                |> Http.stringBody "application/x-www-form-urlencoded"
    in
    Http.post url body userTokenDecoder


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


updateUserAccount : String -> String -> UserToken -> String -> (Result Http.Error Account -> msg) -> Cmd msg
updateUserAccount displayName description userToken serverURL message =
    updateUserAccountRequest displayName description
        |> authRequestWrapper userToken serverURL
        |> Task.attempt message



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


authRequestWrapper : UserToken -> String -> (String -> String -> Http.Request result) -> Task.Task Http.Error result
authRequestWrapper { access_token, refresh_token } serverURL request =
    Http.toTask (request access_token serverURL)
        |> Task.onError
            -- If we fail because of a 401, try refreshing the access_token using the refresh_token
            (\error ->
                if is401 error then
                    Http.toTask (clientRequest serverURL)
                        |> Task.andThen
                            (\{ client_id, client_secret } ->
                                Http.toTask (refreshTokenRequest client_id client_secret refresh_token serverURL)
                            )
                        |> Task.andThen
                            (\userToken ->
                                -- Resend the request with the refreshed access_token
                                Http.toTask (request userToken.access_token serverURL)
                            )

                else
                    Task.fail error
            )

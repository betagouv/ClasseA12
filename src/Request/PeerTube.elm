module Request.PeerTube exposing
    ( AuthError(..)
    , AuthResult(..)
    , PeerTubeResult
    , VideoListParams
    , activate
    , addToFavorite
    , askPasswordReset
    , changePassword
    , deleteVideo
    , emptyVideoListParams
    , extractError
    , extractResult
    , extractSessionMsg
    , extractSessionMsgFromError
    , getAccount
    , getAccountForEdit
    , getBlacklistedVideoList
    , getCommentList
    , getFavoriteStatus
    , getPlaylistVideoList
    , getSpecificPlaylistVideoList
    , getUserInfo
    , getVideo
    , getVideoCommentList
    , getVideoList
    , getVideoRating
    , loadMoreVideos
    , login
    , publishVideo
    , rateVideo
    , register
    , removeFromFavorite
    , submitComment
    , updateUserAccount
    , urlFromVideoListParams
    , userPublishedVideoList
    , videoListRequest
    , withCount
    , withKeyword
    , withKeywords
    )

import Data.PeerTube
    exposing
        ( Account
        , Comment
        , PartialUserInfo
        , Playlist
        , UserInfo
        , UserToken
        , Video
        , accountDecoder
        , alternateCommentListDecoder
        , commentDecoder
        , commentListDecoder
        , playlistDecoder
        , playlistVideoListDataDecoder
        , userInfoDecoder
        , userTokenDecoder
        , videoDecoder
        , videoListDataDecoder
        )
import Data.Session
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Route exposing (Route(..))
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
    , search : String
    , count : Int
    , offset : Int
    }


emptyVideoListParams : VideoListParams
emptyVideoListParams =
    { keywords = []
    , search = ""
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


withCount : Int -> VideoListParams -> VideoListParams
withCount newCount videoListParams =
    { videoListParams | count = newCount }


loadMoreVideos : VideoListParams -> VideoListParams
loadMoreVideos ({ offset, count } as videoListParams) =
    { videoListParams | offset = offset + count }


urlFromVideoListParams : VideoListParams -> String -> String
urlFromVideoListParams { keywords, count, offset, search } serverURL =
    let
        baseURL =
            serverURL
                ++ "/api/v1/search/videos?start="
                ++ String.fromInt offset
                ++ "&count="
                ++ String.fromInt count
                ++ "&categoryOneOf=13&sort=-publishedAt"

        fullURL =
            baseURL
                |> (\url ->
                        if keywords /= [] then
                            keywords
                                |> String.join "&tagsAllOf="
                                |> (++) "&tagsAllOf="
                                |> (++) url

                        else
                            url
                   )
                |> (\url ->
                        if search /= "" then
                            url ++ "&search=" ++ search

                        else
                            url
                   )
    in
    fullURL


videoListRequest : VideoListParams -> String -> Http.Request (List Video)
videoListRequest videoListParams serverURL =
    Http.get (urlFromVideoListParams videoListParams serverURL) videoListDataDecoder


getVideoList : VideoListParams -> String -> (Result Http.Error (List Video) -> msg) -> Cmd msg
getVideoList videoListParams serverURL message =
    Http.send message (videoListRequest videoListParams serverURL)


latestPlaylistRequest : String -> String -> Http.Request Playlist
latestPlaylistRequest username serverURL =
    let
        url =
            serverURL ++ "/api/v1/accounts/" ++ username ++ "/video-playlists"

        playlistsDecoder =
            Decode.field "data" <| Decode.list playlistDecoder

        latestPlaylistDecoder =
            playlistsDecoder
                |> Decode.andThen
                    (\playlists ->
                        case playlists of
                            first :: _ ->
                                Decode.succeed first

                            _ ->
                                Decode.fail "No latest playlist"
                    )
    in
    Http.get url latestPlaylistDecoder


playlistVideoListRequest : VideoListParams -> String -> String -> Http.Request (List Video)
playlistVideoListRequest { count, offset } playlistID serverURL =
    let
        params =
            "start="
                ++ String.fromInt offset
                ++ "&count="
                ++ String.fromInt count

        url =
            serverURL ++ "/api/v1/video-playlists/" ++ playlistID ++ "/videos?" ++ params
    in
    Http.get url playlistVideoListDataDecoder


getPlaylistVideoList : String -> VideoListParams -> String -> (Result Http.Error ( String, List Video ) -> msg) -> Cmd msg
getPlaylistVideoList username videoListParams serverURL message =
    latestPlaylistRequest username serverURL
        |> Http.toTask
        |> Task.andThen
            (\playlist ->
                playlistVideoListRequest videoListParams playlist.uuid serverURL
                    |> Http.toTask
                    |> Task.map
                        (\videoList ->
                            ( playlist.displayName, videoList )
                        )
            )
        |> Task.onError
            -- In case the playlist wasn't created yet return an empty video
            -- list with no title
            (\_ ->
                Task.succeed ( "", [] )
            )
        |> Task.attempt message


specificPlaylistRequest : String -> String -> String -> Http.Request Playlist
specificPlaylistRequest playlistName username serverURL =
    let
        url =
            serverURL ++ "/api/v1/accounts/" ++ username ++ "/video-playlists"

        playlistsDecoder =
            Decode.field "data" <| Decode.list playlistDecoder

        latestPlaylistDecoder =
            playlistsDecoder
                |> Decode.andThen
                    (\playlists ->
                        playlists
                            |> List.filter
                                (\playlist ->
                                    playlist.displayName == playlistName
                                )
                            |> List.head
                            |> Maybe.map Decode.succeed
                            |> Maybe.withDefault (Decode.fail <| "No playlist named " ++ playlistName)
                    )
    in
    Http.get url latestPlaylistDecoder


getSpecificPlaylistVideoList : String -> String -> VideoListParams -> String -> (Result Http.Error (List Video) -> msg) -> Cmd msg
getSpecificPlaylistVideoList playlistName username videoListParams serverURL message =
    specificPlaylistRequest playlistName username serverURL
        |> Http.toTask
        |> Task.andThen
            (\playlist ->
                playlistVideoListRequest videoListParams playlist.uuid serverURL
                    |> Http.toTask
            )
        |> Task.onError
            -- In case the playlist wasn't created yet return an empty video
            -- list with no title
            (\_ ->
                Task.succeed []
            )
        |> Task.attempt message


userPublishedVideoListRequest : String -> VideoListParams -> String -> Http.Request (List Video)
userPublishedVideoListRequest username { count, offset } serverURL =
    let
        params =
            "start="
                ++ String.fromInt offset
                ++ "&count="
                ++ String.fromInt count

        url =
            serverURL ++ "/api/v1/accounts/" ++ username ++ "/videos?" ++ params
    in
    Http.get url videoListDataDecoder


userPublishedVideoList : String -> VideoListParams -> String -> (Result Http.Error (List Video) -> msg) -> Cmd msg
userPublishedVideoList username videoListParams serverURL message =
    userPublishedVideoListRequest username videoListParams serverURL
        |> Http.toTask
        |> Task.attempt message


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


videoDescriptionRequest : String -> String -> Request String
videoDescriptionRequest videoID serverURL =
    let
        url =
            serverURL ++ "/api/v1/videos/" ++ videoID ++ "/description"

        request : Request String
        request =
            { method = "GET"
            , headers = []
            , url = url
            , body = Http.emptyBody
            , expect =
                Http.expectJson
                    (Decode.field "description" (Decode.maybe Decode.string)
                        |> Decode.map (Maybe.withDefault "")
                    )
            , timeout = Nothing
            , withCredentials = False
            }
    in
    request


anonymousVideoDescriptionRequest : String -> String -> Http.Request String
anonymousVideoDescriptionRequest videoID serverURL =
    videoDescriptionRequest videoID serverURL
        |> Http.request


authVideoDescriptionRequest : String -> String -> String -> Http.Request String
authVideoDescriptionRequest videoID access_token serverURL =
    videoDescriptionRequest videoID serverURL
        |> withHeader "Authorization" ("Bearer " ++ access_token)
        |> Http.request


getVideo : String -> Maybe UserToken -> String -> (Result AuthError (AuthResult Video) -> msg) -> Cmd msg
getVideo videoID maybeUserToken serverURL message =
    -- When requesting a video, it will come back with a truncated description, so
    -- it needs another request to grab the full description.
    let
        ( videoTask, descriptionTask ) =
            case maybeUserToken of
                Just userToken ->
                    ( authVideoRequest videoID
                        |> authRequestWrapper userToken serverURL
                    , authVideoDescriptionRequest videoID
                        |> authRequestWrapper userToken serverURL
                    )

                Nothing ->
                    ( anonymousVideoRequest videoID serverURL
                        |> Http.toTask
                        |> Task.map Succeed
                        |> Task.mapError Error
                    , anonymousVideoDescriptionRequest videoID serverURL
                        |> Http.toTask
                        |> Task.map Succeed
                        |> Task.mapError Error
                    )
    in
    videoTask
        |> Task.andThen
            (\videoAuthResult ->
                descriptionTask
                    |> Task.map
                        (\descriptionAuthResult ->
                            let
                                description =
                                    extractResult descriptionAuthResult
                            in
                            updateResult
                                (\video ->
                                    -- Update the video with its full description
                                    { video | description = description }
                                )
                                videoAuthResult
                        )
            )
        |> Task.attempt message


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


getBlacklistedVideoList : UserToken -> String -> (Result AuthError (AuthResult (List Video)) -> msg) -> Cmd msg
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


publishVideo : Video -> UserToken -> String -> (Result AuthError (AuthResult String) -> msg) -> Cmd msg
publishVideo video userToken serverURL message =
    publishVideoRequest video
        |> authRequestWrapper userToken serverURL
        |> Task.attempt message


deleteVideoRequest : Video -> String -> String -> Http.Request String
deleteVideoRequest video access_token serverURL =
    let
        url =
            serverURL ++ "/api/v1/videos/" ++ String.fromInt video.id

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


deleteVideo : Video -> UserToken -> String -> (Result AuthError (AuthResult String) -> msg) -> Cmd msg
deleteVideo video userToken serverURL message =
    deleteVideoRequest video
        |> authRequestWrapper userToken serverURL
        |> Task.attempt message



---- FAVORITES ----


getFavoriteStatusRequest : Int -> String -> String -> Http.Request (Maybe Data.PeerTube.FavoriteData)
getFavoriteStatusRequest videoID access_token serverURL =
    let
        idAsString =
            String.fromInt videoID

        url =
            serverURL ++ "/api/v1/users/me/video-playlists/videos-exist?videoIds=" ++ idAsString

        favoriteDataDecoder =
            Decode.map2 Data.PeerTube.FavoriteData
                (Decode.field "playlistId" Decode.int)
                (Decode.field "playlistElementId" Decode.int)

        decoder =
            Decode.field idAsString
                (Decode.list favoriteDataDecoder
                    |> Decode.map List.head
                )

        request : Http.Request (Maybe Data.PeerTube.FavoriteData)
        request =
            { method = "GET"
            , headers = []
            , url = url
            , body = Http.emptyBody
            , expect = Http.expectJson decoder
            , timeout = Nothing
            , withCredentials = False
            }
                |> withHeader "Authorization" ("Bearer " ++ access_token)
                |> Http.request
    in
    request


getFavoriteStatus : Int -> UserToken -> String -> (Result AuthError (AuthResult (Maybe Data.PeerTube.FavoriteData)) -> msg) -> Cmd msg
getFavoriteStatus videoID userToken serverURL message =
    getFavoriteStatusRequest videoID
        |> authRequestWrapper userToken serverURL
        |> Task.attempt message


createUserPlaylistRequest : Int -> String -> String -> Http.Request Int
createUserPlaylistRequest channelID userToken serverURL =
    let
        url =
            serverURL ++ "/api/v1/video-playlists/"

        decoder =
            Decode.field "videoPlaylist"
                (Decode.field "id" Decode.int)

        data =
            -- For some reason the API doesn't accept anything else than multipart
            -- ... no json, no form-urlencoded.
            [ Http.stringPart "displayName" "favoris"
            , Http.stringPart "privacy" "1" -- Privacy: public
            , Http.stringPart "videoChannelId" <| String.fromInt channelID
            ]

        body =
            data
                |> Http.multipartBody

        request : Http.Request Int
        request =
            { method = "POST"
            , headers = []
            , url = url
            , body = body
            , expect = Http.expectJson decoder
            , timeout = Nothing
            , withCredentials = False
            }
                |> withHeader "Authorization" ("Bearer " ++ userToken)
                |> Http.request
    in
    request


addToFavoriteRequest : Int -> Int -> String -> String -> Http.Request Data.PeerTube.FavoriteData
addToFavoriteRequest videoID playlistID access_token serverURL =
    let
        idAsString =
            String.fromInt playlistID

        url =
            serverURL ++ "/api/v1/video-playlists/" ++ idAsString ++ "/videos"

        body =
            Encode.object
                [ ( "videoId", Encode.string <| String.fromInt videoID )
                ]
                |> Http.jsonBody

        decoder =
            Decode.map (Data.PeerTube.FavoriteData playlistID)
                (Decode.at [ "videoPlaylistElement", "id" ] Decode.int)

        request : Http.Request Data.PeerTube.FavoriteData
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


addToFavorite : Int -> Int -> UserToken -> String -> (Result AuthError (AuthResult Data.PeerTube.FavoriteData) -> msg) -> Cmd msg
addToFavorite videoID playlistID userToken serverURL message =
    addToFavoriteRequest videoID playlistID
        |> authRequestWrapper userToken serverURL
        |> Task.attempt message


removeFromFavoriteRequest : Int -> Int -> String -> String -> Http.Request String
removeFromFavoriteRequest playlistItemID playlistID access_token serverURL =
    let
        playlistIDAsString =
            String.fromInt playlistID

        itemIDAsString =
            String.fromInt playlistItemID

        url =
            serverURL ++ "/api/v1/video-playlists/" ++ playlistIDAsString ++ "/videos/" ++ itemIDAsString

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


removeFromFavorite : Data.PeerTube.FavoriteData -> UserToken -> String -> (Result AuthError (AuthResult String) -> msg) -> Cmd msg
removeFromFavorite { playlistID, playlistItemID } userToken serverURL message =
    removeFromFavoriteRequest playlistItemID playlistID
        |> authRequestWrapper userToken serverURL
        |> Task.attempt message



---- LIKES ----


videoRatingRequest : Video -> String -> String -> Http.Request Data.PeerTube.Rating
videoRatingRequest video access_token serverURL =
    let
        url =
            serverURL ++ "/api/v1/users/me/videos/" ++ String.fromInt video.id ++ "/rating"

        decoder : Decode.Decoder Data.PeerTube.Rating
        decoder =
            Decode.field "rating" Decode.string
                |> Decode.map
                    (\ratingString ->
                        if ratingString == "like" then
                            Data.PeerTube.Liked

                        else
                            Data.PeerTube.NotLiked
                    )

        request : Http.Request Data.PeerTube.Rating
        request =
            { method = "GET"
            , headers = []
            , url = url
            , body = Http.emptyBody
            , expect = Http.expectJson decoder
            , timeout = Nothing
            , withCredentials = False
            }
                |> withHeader "Authorization" ("Bearer " ++ access_token)
                |> Http.request
    in
    request


getVideoRating : Video -> UserToken -> String -> (Result AuthError (AuthResult Data.PeerTube.Rating) -> msg) -> Cmd msg
getVideoRating video userToken serverURL message =
    videoRatingRequest video
        |> authRequestWrapper userToken serverURL
        |> Task.attempt message


rateVideoRequest : Video -> Data.PeerTube.Rating -> String -> String -> Http.Request ()
rateVideoRequest video rating access_token serverURL =
    let
        url =
            serverURL ++ "/api/v1/videos/" ++ String.fromInt video.id ++ "/rate"

        ratingString =
            case rating of
                Data.PeerTube.Liked ->
                    "like"

                _ ->
                    "none"

        request : Http.Request ()
        request =
            { method = "PUT"
            , headers = []
            , url = url
            , body =
                Encode.object
                    [ ( "rating", Encode.string ratingString )
                    ]
                    |> Http.jsonBody
            , expect = Http.expectStringResponse (\_ -> Ok ())
            , timeout = Nothing
            , withCredentials = False
            }
                |> withHeader "Authorization" ("Bearer " ++ access_token)
                |> Http.request
    in
    request


rateVideo : Video -> UserToken -> String -> (Result AuthError (AuthResult ()) -> msg) -> Data.PeerTube.Rating -> Cmd msg
rateVideo video userToken serverURL message rating =
    rateVideoRequest video rating
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


commentListRequest : String -> Http.Request (List Comment)
commentListRequest serverURL =
    let
        url =
            serverURL ++ "/api/v1/videos/comments-feed"
    in
    Http.get url alternateCommentListDecoder


getCommentList : String -> (Result Http.Error (List Comment) -> msg) -> Cmd msg
getCommentList serverURL message =
    Http.send message (commentListRequest serverURL)


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


submitComment : String -> String -> UserToken -> String -> (Result AuthError (AuthResult Comment) -> msg) -> Cmd msg
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
            , ( "email"
              , email
                    |> String.toLower
                    |> Encode.string
              )
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
            [ ( "email"
              , email
                    |> String.toLower
                    |> Encode.string
              )
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


accountRequest : String -> String -> Request Account
accountRequest accountName serverURL =
    let
        url =
            serverURL ++ "/api/v1/accounts/" ++ accountName

        request : Request Account
        request =
            { method = "GET"
            , headers = []
            , url = url
            , body = Http.emptyBody
            , expect = Http.expectJson accountDecoder
            , timeout = Nothing
            , withCredentials = False
            }
    in
    request


getAccount : String -> String -> (Result Http.Error Account -> msg) -> Cmd msg
getAccount accountName serverURL message =
    accountRequest accountName serverURL
        |> Http.request
        |> Http.send message


accountRequestForEdit : String -> String -> String -> Http.Request Account
accountRequestForEdit accountName access_token serverURL =
    accountRequest accountName serverURL
        |> withHeader "Authorization" ("Bearer " ++ access_token)
        |> Http.request


getAccountForEdit : String -> UserToken -> String -> (Result AuthError (AuthResult Account) -> msg) -> Cmd msg
getAccountForEdit accountName userToken serverURL message =
    accountRequestForEdit accountName
        |> authRequestWrapper userToken serverURL
        |> Task.attempt message


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
loginRequest client_id client_secret email password serverURL =
    let
        url =
            serverURL ++ "/api/v1/users/token"

        data =
            [ ( "username"
              , email
                    |> String.toLower
                    |> Url.percentEncode
              )
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
login email password serverURL message =
    Http.toTask (clientRequest serverURL)
        |> Task.andThen
            (\{ client_id, client_secret } ->
                Http.toTask (loginRequest client_id client_secret email password serverURL)
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


getUserInfoRequest : String -> String -> Http.Request PartialUserInfo
getUserInfoRequest access_token serverURL =
    let
        url =
            serverURL ++ "/api/v1/users/me"

        request : Http.Request PartialUserInfo
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
    let
        getUserInfoTask =
            Http.toTask (getUserInfoRequest access_token serverURL)

        getUserPlaylistTask username =
            Http.toTask (latestPlaylistRequest username serverURL)

        createUserPlaylistTask channelID =
            Http.toTask (createUserPlaylistRequest channelID access_token serverURL)
    in
    -- First get the partial user info lacking the playlist ID
    getUserInfoTask
        |> Task.andThen
            (\partialUserInfo ->
                -- Then get the playlist ID
                getUserPlaylistTask partialUserInfo.username
                    |> Task.map
                        -- If there was already a "favoris" playlist use it
                        (\playlist ->
                            { username = partialUserInfo.username
                            , channelID = partialUserInfo.channelID
                            , playlistID = playlist.id
                            }
                        )
                    |> Task.onError
                        -- Otherwise create this "favoris" playlist
                        (\_ ->
                            createUserPlaylistTask partialUserInfo.channelID
                                |> Task.map
                                    (\playlistID ->
                                        { username = partialUserInfo.username
                                        , channelID = partialUserInfo.channelID
                                        , playlistID = playlistID
                                        }
                                    )
                        )
            )
        |> Task.attempt message


updateUserAccountRequest : String -> String -> String -> String -> Http.Request Account
updateUserAccountRequest displayName description access_token serverURL =
    let
        url =
            serverURL ++ "/api/v1/users/me"

        body =
            Encode.object
                [ ( "displayName", Encode.string displayName )
                , ( "description"
                  , if String.length description < 3 then
                        -- A description must be at least 3 chars on peertube
                        Encode.null

                    else
                        Encode.string description
                  )
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


updateUserAccount : String -> String -> UserToken -> String -> (Result AuthError (AuthResult Account) -> msg) -> Cmd msg
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


is400 : Http.Error -> Bool
is400 error =
    case error of
        Http.BadStatus response ->
            response.status.code == 400

        _ ->
            False


is401 : Http.Error -> Bool
is401 error =
    case error of
        Http.BadStatus response ->
            response.status.code == 401

        _ ->
            False


type alias PeerTubeResult result =
    Result AuthError (AuthResult result)


type AuthResult result
    = Succeed result
    | Refreshed UserToken result


type AuthError
    = Unauthorized Http.Error
    | Error Http.Error


authRequestWrapper :
    UserToken
    -> String
    -> (String -> String -> Http.Request result)
    -> Task.Task AuthError (AuthResult result)
authRequestWrapper { access_token, refresh_token } serverURL request =
    Http.toTask (request access_token serverURL)
        |> Task.andThen
            (\result ->
                -- Everything went well, didn't even need a token refresh
                Task.succeed <| Succeed result
            )
        |> Task.onError
            (\error ->
                if is401 error then
                    -- If we fail because of a 401, try refreshing the access_token using the refresh_token
                    Http.toTask (clientRequest serverURL)
                        |> Task.andThen
                            (\{ client_id, client_secret } ->
                                Http.toTask (refreshTokenRequest client_id client_secret refresh_token serverURL)
                                    |> Task.andThen
                                        (\userToken ->
                                            -- Resend the request with the refreshed access_token
                                            Http.toTask (request userToken.access_token serverURL)
                                                |> Task.andThen
                                                    (\result ->
                                                        Task.succeed <| Refreshed userToken result
                                                    )
                                        )
                            )
                        |> Task.mapError
                            (\refreshTokenError ->
                                -- An error occured during the token refresh: 401 (unauthorized) or 400 (bad token)
                                if is400 error || is401 error then
                                    Unauthorized refreshTokenError

                                else
                                    Error refreshTokenError
                            )

                else
                    Task.fail <| Error error
            )


updateResult : (result -> result) -> AuthResult result -> AuthResult result
updateResult updateFunction authResult =
    case authResult of
        Succeed result ->
            updateFunction result
                |> Succeed

        Refreshed userToken result ->
            updateFunction result
                |> Refreshed userToken


extractResult : AuthResult result -> result
extractResult authResult =
    case authResult of
        Succeed result ->
            result

        Refreshed _ result ->
            result


extractSessionMsg : AuthResult result -> Maybe Data.Session.Msg
extractSessionMsg authResult =
    case authResult of
        Succeed _ ->
            Nothing

        Refreshed userToken _ ->
            Just <| Data.Session.RefreshToken userToken


extractError : AuthError -> Http.Error
extractError authError =
    case authError of
        Error error ->
            error

        Unauthorized error ->
            -- If we got an unauthorized, then the access_token and refresh token are expired/wrong
            error


extractSessionMsgFromError : AuthError -> Maybe Data.Session.Msg
extractSessionMsgFromError authError =
    case authError of
        Error _ ->
            Nothing

        Unauthorized _ ->
            -- If we got an unauthorized, then the access_token and refresh token are expired/wrong
            Just Data.Session.Logout

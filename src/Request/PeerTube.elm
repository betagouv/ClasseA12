module Request.PeerTube exposing (getAccount, getVideo, getVideoList)

import Data.PeerTube exposing (Account, Video, accountDecoder, dataDecoder, videoDecoder)
import Http


videoListRequest : Http.Request (List Video)
videoListRequest =
    Http.get "https://peertube.scopyleft.fr/api/v1/video-channels/vincent_channel/videos" dataDecoder


getVideoList : (Result Http.Error (List Video) -> msg) -> Cmd msg
getVideoList message =
    Http.send message videoListRequest


videoRequest : String -> Http.Request Video
videoRequest videoID =
    Http.get ("https://peertube.scopyleft.fr/api/v1/videos/" ++ videoID) videoDecoder


getVideo : String -> (Result Http.Error Video -> msg) -> Cmd msg
getVideo videoID message =
    Http.send message (videoRequest videoID)


accountRequest : String -> Http.Request Account
accountRequest accountName =
    Http.get ("https://peertube.scopyleft.fr/api/v1/accounts/" ++ accountName) accountDecoder


getAccount : String -> (Result Http.Error Account -> msg) -> Cmd msg
getAccount accountName message =
    Http.send message (accountRequest accountName)

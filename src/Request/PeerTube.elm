module Request.PeerTube exposing (getVideoList)

import Http
import Data.PeerTube exposing (Video, dataDecoder)

videoListRequest : Http.Request (List Video)
videoListRequest =
    Http.get "https://peertube.scopyleft.fr/api/v1/video-channels/vincent_channel/videos" dataDecoder


getVideoList : (Result Http.Error (List Video) -> msg) -> Cmd msg
getVideoList message =
    Http.send message videoListRequest

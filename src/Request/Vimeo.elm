module Request.Vimeo exposing (errorToString, getRSS)

import Data.Session exposing (Session)
import Http exposing (Error(..), Request, getString)


errorToString : Http.Error -> String
errorToString error =
    case error of
        BadUrl _ ->
            "Bad url."

        Timeout ->
            "Request timed out."

        NetworkError ->
            "Network error. Are you online?"

        BadStatus response ->
            "HTTP error " ++ String.fromInt response.status.code

        BadPayload _ _ ->
            "Unable to parse response body."


getRSS : Session -> Request String
getRSS _ =
    getString "https://cors.io/?https://vimeo.com/user87116214/videos/rss"

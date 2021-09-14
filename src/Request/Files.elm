module Request.Files exposing (Attachment, attachmentFromString, getVideoAttachmentList)

import Array
import Dict
import Http
import Json.Decode as Decode
import Task


type alias Attachment =
    { commentID : String
    , videoID : String
    , filename : String
    , url : String
    , contentInfo : Maybe ContentInfo
    }


type alias ContentInfo =
    { contentLength : Int
    , mimeType : String
    }


getVideoAttachmentListRequest : String -> String -> Http.Request (List String)
getVideoAttachmentListRequest videoID serverURL =
    let
        url =
            serverURL ++ "/" ++ videoID
    in
    Http.get url (Decode.list Decode.string)


getVideoAttachmentList : String -> String -> (Result (Maybe String) (List Attachment) -> msg) -> Cmd msg
getVideoAttachmentList videoID serverURL message =
    getVideoAttachmentListRequest videoID serverURL
        |> Http.toTask
        |> Task.mapError
            (\error ->
                case error of
                    Http.BadStatus response ->
                        if response.status.code == 404 then
                            -- If there are no attachments, it's an "expected failure", not an error
                            Nothing

                        else
                            Just "Échec de la récupération des pièces jointes"

                    _ ->
                        Just "Échec de la récupération des pièces jointes"
            )
        |> Task.map (List.filterMap (attachmentFromString serverURL))
        |> Task.andThen (List.map contentInfoRequest >> Task.sequence)
        |> Task.attempt message


attachmentFromString : String -> String -> Maybe Attachment
attachmentFromString baseURL str =
    let
        splitted =
            String.split "/" str
                |> Array.fromList

        -- Get the element at the given index, and return an empty string otherwise.
        get : Int -> Array.Array String -> String
        get index array =
            Array.get index array
                |> Maybe.withDefault ""
    in
    if Array.length splitted == 4 then
        -- The file url starts with a "/", so the first element in `splitted` is an empty string
        Just
            { videoID = get 1 splitted
            , commentID = get 2 splitted
            , filename = get 3 splitted
            , url = baseURL ++ str
            , contentInfo = Nothing
            }

    else
        Nothing


contentInfoRequest : Attachment -> Task.Task (Maybe String) Attachment
contentInfoRequest attachment =
    Http.request
        { method = "HEAD"
        , headers = []
        , url = attachment.url
        , body = Http.emptyBody
        , expect = Http.expectStringResponse extractContentInfo
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.toTask
        |> Task.map
            (\contentInfo ->
                { attachment | contentInfo = Just contentInfo }
            )
        |> Task.onError (\_ -> Task.succeed { attachment | contentInfo = Nothing })


extractContentInfo : Http.Response String -> Result String ContentInfo
extractContentInfo response =
    case response.status.code of
        200 ->
            Ok
                { contentLength =
                    Dict.get "content-length" response.headers
                        |> Maybe.andThen String.toInt
                        |> Maybe.withDefault 0
                , mimeType =
                    Dict.get "content-type" response.headers
                        |> Maybe.withDefault ""
                }

        _ ->
            Err <| "Erreur lors de la récupération des infos des pièces jointes"

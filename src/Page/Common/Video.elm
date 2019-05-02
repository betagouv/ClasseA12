module Page.Common.Video exposing
    ( details
    , embedPlayer
    , keywords
    , kintoDetails
    , player
    , playerForVideo
    , rawPlayer
    , shortDetails
    , viewCategory
    )

import Data.Kinto
import Data.PeerTube
import Dict
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode
import Markdown
import Page.Common.Dates as Dates
import Route
import Time


publishedAtFromVideo : Data.PeerTube.Video -> String
publishedAtFromVideo video =
    if video.originallyPublishedAt /= "" then
        video.originallyPublishedAt

    else
        video.publishedAt


player : msg -> Data.Kinto.Attachment -> H.Html msg
player canplayMessage attachment =
    H.video
        [ HA.src <| attachment.location

        -- For some reason, using HA.type_ doesn't properly add the mimetype
        , HA.attribute "type" attachment.mimetype
        , HA.controls True
        , HA.preload "metadata"
        , HE.on "canplay" (Decode.succeed canplayMessage)
        ]
        [ H.text "Désolé, votre navigateur ne supporte pas le format de cette video" ]


embedPlayer : Data.PeerTube.Video -> String -> H.Html msg
embedPlayer video peerTubeURL =
    H.embed
        [ HA.src <| peerTubeURL ++ video.embedPath
        , HA.width 1000
        , HA.height 800
        ]
        []


rawPlayer : Data.PeerTube.Video -> H.Html msg
rawPlayer video =
    let
        videoURL =
            video.files
                |> List.head
                -- If the video is blacklisted and there's no file url there's no way to view the video anyway
                |> Maybe.withDefault ""
    in
    H.video
        [ HA.src videoURL
        , HA.controls True
        , HA.preload "metadata"
        ]
        []


playerForVideo : Data.PeerTube.Video -> String -> H.Html msg
playerForVideo video peerTubeURL =
    if video.blacklisted then
        -- Visible only by admins, the <embed> tag doesn't work as we can't pass it an access_token
        rawPlayer video

    else
        embedPlayer video peerTubeURL


kintoDetails : Time.Zone -> Data.Kinto.Video -> Data.Kinto.ProfileData -> H.Html msg
kintoDetails timezone video profileData =
    let
        authorName =
            case profileData of
                Data.Kinto.Received profile ->
                    profile.name

                _ ->
                    video.profile
    in
    H.div
        [ HA.class "video-details" ]
        [ H.h3 [] [ H.text video.title ]
        , H.div []
            [ H.time [] [ H.text <| Dates.posixToDate timezone video.creation_date ]
            , H.text " "
            , H.a [ Route.href <| Route.Profile video.profile ] [ H.text authorName ]
            ]
        , Markdown.toHtml [] video.description
        ]


details : Data.PeerTube.Video -> H.Html msg
details video =
    H.div
        [ HA.class "video-details" ]
        [ H.h3 [] [ H.text video.name ]
        , H.div []
            [ H.time [] [ H.text <| Dates.formatStringDate (publishedAtFromVideo video) ]
            , H.text " "
            , H.a [ Route.href <| Route.Profile video.account.name ] [ H.text video.account.displayName ]
            ]
        , Markdown.toHtml [] video.description
        ]


shortDetails : Data.PeerTube.Video -> H.Html msg
shortDetails video =
    H.div
        [ HA.class "video-details" ]
        [ H.h3 [] [ H.text video.name ]
        , H.div []
            [ H.time [] [ H.text <| Dates.formatStringDate (publishedAtFromVideo video) ]
            ]
        ]


keywords : List String -> H.Html msg
keywords keywordList =
    if keywordList /= [] then
        keywordList
            |> List.map
                (\keyword ->
                    H.div [ HA.class "label" ]
                        [ H.a [ Route.href <| Route.Search (Just keyword) ]
                            [ H.text keyword ]
                        ]
                )
            |> H.div [ HA.class "video-keywords" ]

    else
        H.text ""


viewCategory : Data.PeerTube.RemoteData (List Data.PeerTube.Video) -> String -> String -> H.Html msg
viewCategory data peerTubeURL keyword =
    H.div [ HA.class "panel", HA.id keyword ]
        [ H.div [ HA.class "panel__header" ]
            [ H.h3 []
                [ H.text keyword
                , H.text " "
                , H.a [ Route.href <| Route.Search <| Just keyword ]
                    [ H.i [ HA.class "fas fa-angle-right" ] []
                    ]
                ]
            ]
        , H.div []
            [ case data of
                Data.PeerTube.NotRequested ->
                    H.text ""

                Data.PeerTube.Requested ->
                    H.text "Chargement des vidéos..."

                Data.PeerTube.Received videoList ->
                    viewList keyword peerTubeURL videoList

                Data.PeerTube.Failed error ->
                    H.text error
            ]
        ]


viewList :
    String
    -> String
    -> List Data.PeerTube.Video
    -> H.Html msg
viewList title peerTubeURL videoList =
    let
        videoCards =
            if videoList /= [] then
                videoList
                    |> List.map (\video -> viewVideo peerTubeURL video)

            else
                [ H.text "Aucune vidéo pour le moment" ]
    in
    H.div [ HA.class "row" ]
        videoCards


viewVideo : String -> Data.PeerTube.Video -> H.Html msg
viewVideo peerTubeURL video =
    H.a
        [ HA.class "card"
        , Route.href <| Route.Video video.uuid video.name
        ]
        [ H.div
            [ HA.class "card__cover" ]
            [ H.img
                [ HA.alt video.name
                , HA.src (peerTubeURL ++ video.previewPath)
                ]
                []
            ]
        , shortDetails video
        ]

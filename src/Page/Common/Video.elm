module Page.Common.Video exposing
    ( description
    , details
    , embedPlayer
    , keywords
    , metadata
    , playerForVideo
    , rawPlayer
    , shortDetails
    , title
    , viewCategory
    , viewVideo
    , viewVideoListData
    )

import Data.PeerTube
import Html as H
import Html.Attributes as HA
import Markdown
import Page.Common.Dates as Dates
import Route


publishedAtFromVideo : Data.PeerTube.Video -> String
publishedAtFromVideo video =
    if video.originallyPublishedAt /= "" then
        video.originallyPublishedAt

    else
        video.publishedAt


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


details : Data.PeerTube.Video -> H.Html msg
details video =
    H.div
        [ HA.class "video_details" ]
        [ H.h1 [ HA.class "video_title" ] [ H.text video.name ]
        , H.div [ HA.class "video_metadata" ]
            [ H.text "Par "
            , H.a [ Route.href <| Route.Profile video.account.name ] [ H.text video.account.displayName ]
            , H.text " le "
            , H.time [] [ H.text <| Dates.formatStringDate (publishedAtFromVideo video) ]
            ]
        ]


title : Data.PeerTube.Video -> H.Html msg
title video =
    H.h1 [ HA.class "video_title" ] [ H.text video.name ]


metadata : Data.PeerTube.Video -> H.Html msg
metadata video =
    H.div [ HA.class "video_metadata" ]
        [ H.text "Par "
        , H.a [ Route.href <| Route.Profile video.account.name ] [ H.text video.account.displayName ]
        , H.text " le "
        , H.time [] [ H.text <| Dates.formatStringDate (publishedAtFromVideo video) ]
        ]


description : Data.PeerTube.Video -> H.Html msg
description video =
    H.div
        [ HA.class "video_description" ]
        [ Markdown.toHtml [] video.description ]


shortDetails : Data.PeerTube.Video -> H.Html msg
shortDetails video =
    H.div
        [ HA.class "card_content" ]
        [ H.h3 [] [ H.text video.name ]
        , H.time [ HA.class "card_date" ] [ H.text <| Dates.formatStringDate (publishedAtFromVideo video) ]
        ]


keywords : List String -> H.Html msg
keywords keywordList =
    if keywordList /= [] then
        keywordList
            |> List.map
                (\keyword ->
                    H.li [ HA.class "label" ]
                        [ H.a [ Route.href <| Route.VideoList (Route.Search keyword) ]
                            [ H.text keyword ]
                        ]
                )
            |> H.ul [ HA.class "video_keywords" ]

    else
        H.text ""


viewCategory : Data.PeerTube.RemoteData (List Data.PeerTube.Video) -> String -> Route.VideoListQuery -> H.Html msg
viewCategory data peerTubeURL query =
    let
        displayedKeyword =
            case query of
                Route.Latest ->
                    "nouveautés"

                Route.Playlist ->
                    "playlist de la semaine"

                Route.Keyword keyword ->
                    keyword

                Route.Search search ->
                    search
    in
    H.section [ HA.class "category", HA.id displayedKeyword ]
        [ H.div [ HA.class "home-title_wrapper" ]
            [ H.h3 [ HA.class "home-title" ]
                [ H.text "Le coin "
                , H.text displayedKeyword
                ]
            , H.a [ Route.href <| Route.VideoList query ]
                [ H.text "Toutes les vidéos "
                , H.text displayedKeyword
                ]
            ]
        , viewVideoListData data peerTubeURL
        ]


viewVideoListData : Data.PeerTube.RemoteData (List Data.PeerTube.Video) -> String -> H.Html msg
viewVideoListData data peerTubeURL =
    H.div []
        [ case data of
            Data.PeerTube.NotRequested ->
                H.text ""

            Data.PeerTube.Requested ->
                H.text "Chargement des vidéos..."

            Data.PeerTube.Received videoList ->
                viewList peerTubeURL videoList

            Data.PeerTube.Failed error ->
                H.text error
        ]


viewList : String -> List Data.PeerTube.Video -> H.Html msg
viewList peerTubeURL videoList =
    let
        videoCards =
            if videoList /= [] then
                videoList
                    |> List.map (\video -> viewVideo peerTubeURL video)

            else
                [ H.text "Aucune vidéo pour le moment" ]
    in
    H.div [ HA.class "grid" ]
        videoCards


viewVideo : String -> Data.PeerTube.Video -> H.Html msg
viewVideo peerTubeURL video =
    H.a
        [ HA.class "card"
        , Route.href <| Route.Video video.uuid video.name
        ]
        [ H.div
            [ HA.class "card_img" ]
            [ H.img
                [ HA.alt video.name
                , HA.src (peerTubeURL ++ video.previewPath)
                ]
                []
            ]
        , shortDetails video
        ]

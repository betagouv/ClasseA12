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
import Dict
import Html as H
import Html.Attributes as HA
import Markdown
import Page.Common.Dates as Dates
import Route
import String.Normalize


publishedAtFromVideo : Data.PeerTube.Video -> String
publishedAtFromVideo video =
    if video.originallyPublishedAt /= "" then
        video.originallyPublishedAt

    else
        video.publishedAt


embedPlayer : Data.PeerTube.Video -> String -> H.Html msg
embedPlayer video peerTubeURL =
    H.div [HA.class "video_wrapper"]
        [ H.embed
            [ HA.src <| peerTubeURL ++ video.embedPath ++ "?warningTitle=false"
            ]
            []
        ]


rawPlayer : Data.PeerTube.Video -> H.Html msg
rawPlayer video =
    let
        videoURL =
            video.files
                |> Maybe.map .fileUrl
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


titleForQuery : Route.VideoListQuery -> String
titleForQuery query =
    case query of
        Route.Latest ->
            "Les nouveautés"

        Route.Playlist ->
            "La playlist de la semaine"

        Route.FAQFlash ->
            "FAQ Flash"

        Route.Keyword keyword ->
            keyword

        Route.Search search ->
            search

        Route.Favorites profile ->
            "Les vidéos favorites de " ++ profile

        Route.Published profile ->
            "Les vidéos publiées par " ++ profile


textContentForQuery : Route.VideoListQuery -> String
textContentForQuery query =
    case query of
        Route.Latest ->
            "Du texte pour l'encart de les nouveautés"

        Route.Playlist ->
            "Du texte pour l'encart de la playlist de la semaine"

        Route.FAQFlash ->
            "Du texte pour l'encart de la FAQ Flash"

        Route.Keyword keyword ->
            Dict.fromList
                [ ( "Français", "Du texte pour l'encart de Français" )
                , ( "Mathématiques", "Du texte pour l'encart de Mathématiques" )
                , ( "Questionner le monde", "Du texte pour l'encart de Questionner le monde" )
                , ( "Arts", "Du texte pour l'encart de Arts" )
                , ( "Numérique", "Du texte pour l'encart de Numérique" )
                , ( "Enseignement moral et civique", "Du texte pour l'encart de Enseignement moral et civique" )
                , ( "Gestion de classe", "Du texte pour l'encart de Gestion de classe" )
                , ( "Outils", "Du texte pour l'encart de Outils" )
                ]
                |> Dict.get keyword
                |> Maybe.withDefault ""

        _ ->
            ""


viewCategory : Data.PeerTube.RemoteData (List Data.PeerTube.Video) -> String -> Route.VideoListQuery -> H.Html msg
viewCategory data peerTubeURL query =
    let
        categoryTitle =
            titleForQuery query
    in
    H.section [ HA.class "category", HA.id <| String.Normalize.slug categoryTitle ]
        [ H.div [ HA.class "title_wrapper" ]
            [ H.h3 [ HA.class "title" ]
                [ H.img [ HA.src <| "%PUBLIC_URL%/images/icons/48x48/" ++ String.Normalize.slug categoryTitle ++ "_48_bicolore.svg", HA.alt "" ] []
                , H.text "Le coin "
                , H.text categoryTitle
                ]
            ]
        , viewVideoListData query data peerTubeURL
        ]


viewVideoListData : Route.VideoListQuery -> Data.PeerTube.RemoteData (List Data.PeerTube.Video) -> String -> H.Html msg
viewVideoListData query data peerTubeURL =
    case data of
        Data.PeerTube.NotRequested ->
            H.text ""

        Data.PeerTube.Requested ->
            H.text "Chargement des vidéos..."

        Data.PeerTube.Received videoList ->
            viewList query peerTubeURL videoList

        Data.PeerTube.Failed error ->
            H.text error


viewList : Route.VideoListQuery -> String -> List Data.PeerTube.Video -> H.Html msg
viewList query peerTubeURL videoList =
    let
        videoCards =
            if videoList /= [] then
                videoList
                    |> List.map (\video -> viewVideo peerTubeURL video)

            else
                [ H.text "Aucune vidéo pour le moment" ]
    in
    H.div [ HA.class "video-grid" ]
        (viewInsert query
            :: videoCards
        )


viewInsert : Route.VideoListQuery -> H.Html msg
viewInsert query =
    let
        categoryTitle =
            titleForQuery query

        textContent =
            textContentForQuery query
    in
    H.div [ HA.class "video-grid__insert" ]
        [ H.img
            [ HA.src <| "%PUBLIC_URL%/images/illustrations/inserts/desktop_illu_" ++ String.Normalize.slug categoryTitle ++ "@2x.png"
            , HA.alt ""
            ]
            []
        , H.div []
            [ H.h4 [] [ H.text categoryTitle ]
            , H.p [] [ H.text textContent ]
            , H.a
                [ Route.href <| Route.VideoList query
                , HA.class "btn btn--secondary"
                ]
                [ H.text "Voir les vidéos" ]
            ]
        ]


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
                , HA.src (peerTubeURL ++ video.thumbnailPath)
                ]
                []
            ]
        , shortDetails video
        ]

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
    H.div [ HA.class "video_wrapper" ]
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


shortDetails : List Data.PeerTube.VideoID -> Data.PeerTube.Video -> H.Html msg
shortDetails userRatedVideoIDs video =
    let
        videoLikesNode =
            let
                likes =
                    if video.likes > 0 then
                        String.fromInt video.likes

                    else
                        ""

                icon =
                    if List.member video.id userRatedVideoIDs then
                        "%PUBLIC_URL%/images/icons/16x16/heart-filled_16_deepgreen.svg"

                    else
                        "%PUBLIC_URL%/images/icons/16x16/heart_16_deepgreen.svg"
            in
            H.div [ HA.class "card_likes" ]
                [ H.text likes
                , H.img
                    [ HA.src icon
                    ]
                    []
                ]
    in
    H.div
        [ HA.class "card_content" ]
        [ H.h3 [] [ H.text video.name ]
        , H.div [ HA.class "card_meta" ]
            [ H.time [ HA.class "card_date" ] [ H.text <| Dates.formatStringDate (publishedAtFromVideo video) ]
            , videoLikesNode
            ]
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
            "La thématique du mois"

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
            "Découvrez sans attendre nos dernières publications et inspirez-vous de ces propositions !"

        Route.Playlist ->
            "Une thématique proposée chaque mois pour découvrir ou redécouvrir des vidéos sélectionnées selon un thème, un sujet, un auteur, ou une académie."

        Route.Keyword keyword ->
            Dict.fromList
                [ ( "Gestion de groupe", "Retrouvez ici des outils, des conseils et des propositions pour vous aider à gérer et organiser le groupe d’élèves pendant vos séances." )
                , ( "Gestion de matériel", "Repenser la salle et le matériel pour gagner en efficacité lors des séances. Des propositions pour réfléchir à l’aménagement de votre salle et des astuces pour organiser la gestion du matériel." )
                , ( "Co-intervention", "Dans cette rubrique, découvrez des exemples de collaborations entre le premier et le second degré etdes propositions pour associer les parents au dispositif." )
                , ( "Communication", "Les utilisateurs partagent des outils très concrets, variés et faciles à utiliser pour communiquer autour du dispositif." )
                , ( "Devoirs Faits à distance", "Des présentations, des retours d'expérience et des outils pour aider à la mise en place de devoirs faits à distance." )
                , ( "Coordonnateur Devoirs Faits", "Des outils pour aider le coordonnateur à la mise en place et au pilotage du dispositif. <br>Une boîte à outils indispensable pour faire vivre le dispositif." )
                , ( "Ressources", "Des vidéos pour s’inspirer et aider à la mise en œuvre du dispositif dans l’établissement. Dans cette rubrique, retrouvez de nombreux outils à télécharger " )
                ]
                |> Dict.get keyword
                |> Maybe.withDefault ""

        _ ->
            ""


viewCategory : Data.PeerTube.RemoteData (List Data.PeerTube.Video) -> String -> List Data.PeerTube.VideoID -> Route.VideoListQuery -> H.Html msg
viewCategory data peerTubeURL userRatedVideoIDs query =
    let
        categoryTitle =
            titleForQuery query
    in
    H.section [ HA.class "category", HA.id <| String.Normalize.slug categoryTitle ]
        [ H.div [ HA.class "title_wrapper" ]
            [ H.h3 [ HA.class "title" ]
                [ H.img [ HA.src <| "%PUBLIC_URL%/images/icons/48x48/" ++ String.Normalize.slug categoryTitle ++ "_48_bicolore.svg", HA.alt "" ] []
                , H.text categoryTitle
                ]
            ]
        , viewVideoListData query data peerTubeURL userRatedVideoIDs
        ]


viewVideoListData : Route.VideoListQuery -> Data.PeerTube.RemoteData (List Data.PeerTube.Video) -> String -> List Data.PeerTube.VideoID -> H.Html msg
viewVideoListData query data peerTubeURL userRatedVideoIDs =
    case data of
        Data.PeerTube.NotRequested ->
            H.text ""

        Data.PeerTube.Requested ->
            H.text "Chargement des vidéos..."

        Data.PeerTube.Received videoList ->
            viewList query peerTubeURL userRatedVideoIDs videoList

        Data.PeerTube.Failed error ->
            H.text error


viewList : Route.VideoListQuery -> String -> List Data.PeerTube.VideoID -> List Data.PeerTube.Video -> H.Html msg
viewList query peerTubeURL userRatedVideoIDs videoList =
    let
        videoCards =
            if videoList /= [] then
                videoList
                    |> List.map (\video -> viewVideo peerTubeURL userRatedVideoIDs video)

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
        [ H.node "picture"
            []
            [ H.source
                [ HA.media "(min-width: 1024px)"
                , HA.attribute "srcset" <| "%PUBLIC_URL%/images/illustrations/inserts/desktop_illu_" ++ String.Normalize.slug categoryTitle ++ ".png 1x, %PUBLIC_URL%/images/illustrations/inserts/desktop_illu_" ++ String.Normalize.slug categoryTitle ++ "@2x.png 2x"
                ]
                []
            , H.source
                [ HA.media "(min-width: 768px)"
                , HA.attribute "srcset" <| "%PUBLIC_URL%/images/illustrations/inserts/tablette_illu_" ++ String.Normalize.slug categoryTitle ++ ".png 1x, %PUBLIC_URL%/images/illustrations/inserts/tablette_illu_" ++ String.Normalize.slug categoryTitle ++ "@2x.png 2x"
                ]
                []
            , H.source
                [ HA.media "(max-width: 768px)"
                , HA.attribute "srcset" <| "%PUBLIC_URL%/images/illustrations/inserts/mobile_illu_" ++ String.Normalize.slug categoryTitle ++ ".png 1x, %PUBLIC_URL%/images/illustrations/inserts/mobile_illu_" ++ String.Normalize.slug categoryTitle ++ "@2x.png 2x"
                ]
                []
            , H.img
                [ HA.src <| "%PUBLIC_URL%/images/illustrations/inserts/desktop_illu_" ++ String.Normalize.slug categoryTitle ++ ".png"
                ]
                []
            ]
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


viewVideo : String -> List Data.PeerTube.VideoID -> Data.PeerTube.Video -> H.Html msg
viewVideo peerTubeURL userRatedVideoIDs video =
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
        , shortDetails userRatedVideoIDs video
        ]

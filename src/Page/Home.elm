module Page.Home exposing (Model, Msg(..), init, update, view)

import Data.Kinto
import Data.PeerTube
import Data.Session exposing (Session)
import Dict
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Page.Common.Components
import Page.Common.Video
import Request.PeerTube
import Route


type alias Model =
    { title : String
    , search : String
    , recentVideoData : Data.PeerTube.RemoteData (List Data.PeerTube.Video)
    , videoData : Dict.Dict String (Data.PeerTube.RemoteData (List Data.PeerTube.Video))
    }


type Msg
    = UpdateSearch String
    | RecentVideoListReceived (Result Http.Error (List Data.PeerTube.Video))
    | VideoListReceived String (Result Http.Error (List Data.PeerTube.Video))


init : Session -> ( Model, Cmd Msg )
init session =
    let
        keywordList =
            Data.Kinto.keywordList
                |> List.map (\( keyword, _ ) -> keyword)
    in
    ( { title = "Liste des vidéos"
      , search = ""
      , recentVideoData = Data.PeerTube.Requested
      , videoData =
            keywordList
                |> List.foldl
                    (\keyword videoData ->
                        videoData
                            |> Dict.insert keyword Data.PeerTube.Requested
                    )
                    Dict.empty
      }
    , Cmd.batch
        ([ Request.PeerTube.getRecentVideoList session.peerTubeURL RecentVideoListReceived
         ]
            ++ (keywordList
                    |> List.map
                        (\keyword ->
                            Request.PeerTube.getVideoList keyword session.peerTubeURL (VideoListReceived keyword)
                        )
               )
        )
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        UpdateSearch newSearch ->
            ( { model | search = newSearch }, Cmd.none )

        RecentVideoListReceived (Ok videoList) ->
            ( { model | recentVideoData = Data.PeerTube.Received videoList }
            , Cmd.none
            )

        RecentVideoListReceived (Err error) ->
            ( { model | recentVideoData = Data.PeerTube.Failed "Échec de la récupération des vidéos" }, Cmd.none )

        VideoListReceived keyword (Ok videoList) ->
            ( { model
                | videoData =
                    Dict.insert
                        keyword
                        (Data.PeerTube.Received videoList)
                        model.videoData
              }
            , Cmd.none
            )

        VideoListReceived keyword (Err error) ->
            ( { model
                | videoData =
                    Dict.insert
                        keyword
                        (Data.PeerTube.Failed "Échec de la récupération des vidéos")
                        model.videoData
              }
            , Cmd.none
            )


view : Session -> Model -> ( String, List (H.Html Msg) )
view { staticFiles, peerTubeURL } ({ title, search, recentVideoData, videoData } as model) =
    let
        viewRecentVideo =
            [ H.div [ HA.class "panel", HA.id "Nouveautés" ]
                [ H.div [ HA.class "panel__header" ]
                    [ H.h3 []
                        [ H.text "Nouveautés"
                        , H.text " "
                        , H.a [ Route.href <| Route.Search Nothing ]
                            [ H.i [ HA.class "fas fa-angle-right" ] []
                            ]
                        ]
                    ]
                , H.div []
                    [ case recentVideoData of
                        Data.PeerTube.NotRequested ->
                            H.text ""

                        Data.PeerTube.Requested ->
                            H.text "Chargement des vidéos..."

                        Data.PeerTube.Received videoList ->
                            viewVideoList "Nouveautés" peerTubeURL videoList

                        Data.PeerTube.Failed error ->
                            H.text error
                    ]
                ]
            ]

        viewVideoCategories =
            Data.Kinto.keywordList
                |> List.map
                    (\( keyword, _ ) ->
                        let
                            remoteData =
                                Dict.get keyword videoData
                                    |> Maybe.withDefault Data.PeerTube.NotRequested
                        in
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
                                [ case remoteData of
                                    Data.PeerTube.NotRequested ->
                                        H.text ""

                                    Data.PeerTube.Requested ->
                                        H.text "Chargement des vidéos..."

                                    Data.PeerTube.Received videoList ->
                                        viewVideoList keyword peerTubeURL videoList

                                    Data.PeerTube.Failed error ->
                                        H.text error
                                ]
                            ]
                    )
    in
    ( title
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__banner" ] []
            , H.div [ HA.class "hero__container" ]
                [ H.img
                    [ HA.src staticFiles.logo_ca12
                    , HA.class "hero__logo"
                    ]
                    []
                , H.h1 []
                    [ H.text "Classe à 12 en vidéo" ]
                , H.p []
                    [ H.text "Échangeons nos pratiques en toute simplicité !" ]
                ]
            ]
      , H.div [ HA.class "dashboard" ]
            [ H.aside [ HA.class "side-menu" ]
                [ H.ul []
                    (Data.Kinto.keywordList
                        |> List.map
                            (\( keyword, _ ) ->
                                H.li [] [ H.a [ Route.href <| Route.Search (Just keyword) ] [ H.text keyword ] ]
                            )
                    )
                ]
            , H.div [ HA.class "main" ]
                (viewRecentVideo
                    ++ viewVideoCategories
                )
            ]
      ]
    )


viewVideoList :
    String
    -> String
    -> List Data.PeerTube.Video
    -> H.Html Msg
viewVideoList title peerTubeURL videoList =
    let
        videoCards =
            if videoList /= [] then
                videoList
                    |> List.map (\video -> viewPublicVideo peerTubeURL video)

            else
                [ H.text "Aucune vidéo pour le moment" ]
    in
    H.div [ HA.class "row" ]
        videoCards


viewPublicVideo : String -> Data.PeerTube.Video -> H.Html msg
viewPublicVideo peerTubeURL video =
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
        , Page.Common.Video.shortDetails video
        ]

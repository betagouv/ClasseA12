module Page.Home exposing (Model, Msg(..), init, update, view)

import Data.PeerTube
import Data.Session exposing (Session)
import Dict
import Html as H
import Html.Attributes as HA
import Http
import Page.Common.Components
import Page.Common.Video
import Request.PeerTube
import Route


type alias Model =
    { title : String
    , search : String
    , recentVideoData : Data.PeerTube.RemoteData (List Data.PeerTube.Video)
    , playlistVideoData : Data.PeerTube.RemoteData (List Data.PeerTube.Video)
    , playlistTitle : String
    , videoData : Dict.Dict String (Data.PeerTube.RemoteData (List Data.PeerTube.Video))
    }


type Msg
    = UpdateSearch String
    | RecentVideoListReceived (Result Http.Error (List Data.PeerTube.Video))
    | PlaylistVideoListReceived (Result Http.Error ( String, List Data.PeerTube.Video ))
    | VideoListReceived String (Result Http.Error (List Data.PeerTube.Video))


init : Session -> ( Model, Cmd Msg )
init session =
    let
        keywordList =
            Data.PeerTube.keywordList
                |> List.map (\( keyword, _ ) -> keyword)
    in
    ( { title = "Échangeons nos pratiques pédagogiques en vidéo"
      , search = ""
      , recentVideoData = Data.PeerTube.Requested
      , playlistVideoData = Data.PeerTube.Requested
      , playlistTitle = ""
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
        ([ Request.PeerTube.getVideoList
            Request.PeerTube.emptyVideoListParams
            session.peerTubeURL
            RecentVideoListReceived
         , Request.PeerTube.getPlaylistVideoList
            "classea12"
            Request.PeerTube.emptyVideoListParams
            session.peerTubeURL
            PlaylistVideoListReceived
         ]
            ++ (keywordList
                    |> List.map
                        (\keyword ->
                            let
                                videoListParams =
                                    Request.PeerTube.emptyVideoListParams
                                        |> Request.PeerTube.withKeyword keyword
                            in
                            Request.PeerTube.getVideoList videoListParams session.peerTubeURL (VideoListReceived keyword)
                        )
               )
        )
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        UpdateSearch newSearch ->
            ( { model | search = newSearch }, Cmd.none )

        RecentVideoListReceived (Ok videoList) ->
            ( { model | recentVideoData = Data.PeerTube.Received videoList }
            , Cmd.none
            )

        RecentVideoListReceived (Err _) ->
            ( { model | recentVideoData = Data.PeerTube.Failed "Échec de la récupération des vidéos récentes" }, Cmd.none )

        PlaylistVideoListReceived (Ok ( playlistTitle, videoList )) ->
            ( { model
                | playlistVideoData = Data.PeerTube.Received videoList
                , playlistTitle = playlistTitle
              }
            , Cmd.none
            )

        PlaylistVideoListReceived (Err _) ->
            ( { model | playlistVideoData = Data.PeerTube.Failed "Échec de la récupération des vidéos de la playlist" }, Cmd.none )

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

        VideoListReceived keyword (Err _) ->
            ( { model
                | videoData =
                    Dict.insert
                        keyword
                        (Data.PeerTube.Failed "Échec de la récupération des vidéos")
                        model.videoData
              }
            , Cmd.none
            )


view : Session -> Model -> Page.Common.Components.Document Msg
view { peerTubeURL } { title, recentVideoData, playlistVideoData, playlistTitle, videoData } =
    let
        viewRecentVideo =
            [ H.section [ HA.class "category", HA.id "latest" ]
                [ H.div [ HA.class "home-title_wrapper" ]
                    [ H.h3 [ HA.class "home-title" ]
                        [ H.text "Les nouveautés"
                        ]
                    , H.a [ Route.href <| Route.VideoList Route.Latest ]
                        [ H.text "Toutes les vidéos récentes"
                        ]
                    ]
                , Page.Common.Video.viewVideoListData recentVideoData peerTubeURL
                ]
            ]

        viewPlaylistVideo =
            let
                playlistName =
                    if playlistTitle /= "" then
                        " : " ++ playlistTitle

                    else
                        ""
            in
            [ H.section [ HA.class "category", HA.id "playlist" ]
                [ H.div [ HA.class "home-title_wrapper" ]
                    [ H.h3 [ HA.class "home-title" ]
                        [ H.text <| "La playlist de la semaine" ++ playlistName
                        ]
                    , H.a [ Route.href <| Route.VideoList Route.Playlist ]
                        [ H.text "Toutes les vidéos de la playlist"
                        ]
                    ]
                , Page.Common.Video.viewVideoListData playlistVideoData peerTubeURL
                ]
            ]

        viewVideoCategories =
            Data.PeerTube.keywordList
                |> List.map
                    (\( keyword, _ ) ->
                        let
                            videoListData =
                                Dict.get keyword videoData
                                    |> Maybe.withDefault Data.PeerTube.NotRequested
                        in
                        Page.Common.Video.viewCategory videoListData peerTubeURL <| Route.Search keyword
                    )
    in
    { title = title
    , pageTitle = "Classe à 12 en vidéo"
    , pageSubTitle = "Échangeons nos pratiques en toute simplicité !"
    , body =
        viewRecentVideo
            ++ viewPlaylistVideo
            ++ viewVideoCategories
    }

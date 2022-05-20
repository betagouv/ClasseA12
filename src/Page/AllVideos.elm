module Page.AllVideos exposing (Model, Msg(..), init, update, view)

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
    ( { title = "Toutes les vidéos"
      , search = ""
      , recentVideoData = Data.PeerTube.Requested
      , playlistVideoData = Data.PeerTube.Requested
      , playlistTitle = ""
      , videoData =
            Data.PeerTube.keywordList
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
            "devoirsfaits"
            Request.PeerTube.emptyVideoListParams
            session.peerTubeURL
            PlaylistVideoListReceived
         ]
            ++ (Data.PeerTube.keywordList
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
view { peerTubeURL, userRatedVideoIDs } { title, recentVideoData, playlistVideoData, playlistTitle, videoData } =
    let
        viewRecentVideo =
            [ H.section [ HA.class "category", HA.id "latest" ]
                [ H.div [ HA.class "title_wrapper" ]
                    [ H.h2 [ HA.class "title" ]
                        [ H.img [ HA.src "%PUBLIC_URL%/images/icons/48x48/new_48_bicolore.svg", HA.alt "" ] []
                        , H.text "Les nouveautés"
                        ]
                    ]
                , Page.Common.Video.viewVideoListData Route.Latest recentVideoData peerTubeURL userRatedVideoIDs
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
            [ H.section [ HA.class "category insert-wide", HA.id "playlist" ]
                [ H.div [ HA.class "title_wrapper" ]
                    [ H.h1 [ HA.class "title" ]
                        [ H.img [ HA.src "%PUBLIC_URL%/images/icons/48x48/alaune_48_bicolore.svg", HA.alt "" ] []
                        , H.text <| "La playlist de la semaine" ++ playlistName
                        ]
                    ]
                , Page.Common.Video.viewVideoListData Route.Playlist playlistVideoData peerTubeURL userRatedVideoIDs
                ]
            ]

        viewVideoCategories =
            Data.PeerTube.keywordList
                |> List.map
                    (\keyword ->
                        let
                            videoListData =
                                Dict.get keyword videoData
                                    |> Maybe.withDefault Data.PeerTube.NotRequested
                        in
                        Page.Common.Video.viewCategory videoListData peerTubeURL userRatedVideoIDs <| Route.Keyword keyword
                    )
    in
    { title = title
    , pageTitle = "Devoirs Faits en vidéo"
    , pageSubTitle = "Échangeons nos pratiques en toute simplicité !"
    , body =
        viewPlaylistVideo
            ++ viewRecentVideo
            ++ viewVideoCategories
    }

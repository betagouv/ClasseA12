module Page.Home exposing (Model, Msg(..), init, update, view)

import Data.PeerTube
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Http
import Page.Common.Components
import Page.Common.Video
import Request.PeerTube
import Route


type alias Model =
    { title : String
    , playlistVideoData : Data.PeerTube.RemoteData (List Data.PeerTube.Video)
    }


type Msg
    = PlaylistVideoListReceived (Result Http.Error ( String, List Data.PeerTube.Video ))


init : Session -> ( Model, Cmd Msg )
init session =
    ( { title = "Échangeons nos pratiques pédagogiques en vidéo"
      , playlistVideoData = Data.PeerTube.Requested
      }
    , Request.PeerTube.getPlaylistVideoList
        "classea12"
        Request.PeerTube.emptyVideoListParams
        session.peerTubeURL
        PlaylistVideoListReceived
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        PlaylistVideoListReceived (Ok ( _, videoList )) ->
            ( { model
                | playlistVideoData = Data.PeerTube.Received videoList
              }
            , Cmd.none
            )

        PlaylistVideoListReceived (Err _) ->
            ( { model | playlistVideoData = Data.PeerTube.Failed "Échec de la récupération des vidéos de la playlist" }, Cmd.none )


view : Session -> Model -> Page.Common.Components.Document Msg
view { peerTubeURL } { title, playlistVideoData } =
    let
        viewPlaylistVideo =
            [ H.section [ HA.class "category", HA.id "playlist" ]
                [ H.div []
                    [ H.h3 []
                        [ H.text "La communauté vidéo" ]
                    , H.h4 []
                        [ H.text "des enseignants en classe à 12" ]
                    , H.text "Chaque semaine, des enseignants de classe à 12 partagent leurs idées pédagogiques, ateliers, bonnes pratique dans des formats courts."
                    , H.a [ Route.href Route.AllVideos ]
                        [ H.text "Découvrez les vidéos pédagogiques"
                        ]
                    , H.a [ Route.href Route.About ]
                        [ H.text "Découvrez Classe à 12"
                        ]
                    ]
                , H.div [ HA.class "home-title_wrapper" ]
                    [ H.h3 [ HA.class "home-title" ]
                        [ H.text "Les vidéos à la une"
                        ]
                    , H.a [ Route.href Route.AllVideos ]
                        [ H.text "Voir toutes les vidéos"
                        ]
                    ]
                , Page.Common.Video.viewVideoListData playlistVideoData peerTubeURL
                ]
            ]
    in
    { title = title
    , pageTitle = "Classe à 12 en vidéo"
    , pageSubTitle = "Échangeons nos pratiques en toute simplicité !"
    , body = viewPlaylistVideo
    }

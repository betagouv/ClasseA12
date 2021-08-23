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
    , playlistTitle : String
    }


type Msg
    = PlaylistVideoListReceived (Result Http.Error ( String, List Data.PeerTube.Video ))


init : Session -> ( Model, Cmd Msg )
init session =
    ( { title = "Échangeons nos pratiques pédagogiques en vidéo"
      , playlistVideoData = Data.PeerTube.Requested
      , playlistTitle = ""
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
        PlaylistVideoListReceived (Ok ( playlistTitle, videoList )) ->
            ( { model
                | playlistVideoData = Data.PeerTube.Received videoList
                , playlistTitle = playlistTitle
              }
            , Cmd.none
            )

        PlaylistVideoListReceived (Err _) ->
            ( { model | playlistVideoData = Data.PeerTube.Failed "Échec de la récupération des vidéos de la playlist" }, Cmd.none )


view : Session -> Model -> Page.Common.Components.Document Msg
view { peerTubeURL } { title, playlistVideoData, playlistTitle } =
    let
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
    in
    { title = title
    , pageTitle = "Classe à 12 en vidéo"
    , pageSubTitle = "Échangeons nos pratiques en toute simplicité !"
    , body = viewPlaylistVideo
    }

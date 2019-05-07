module Page.Home exposing (Model, Msg(..), init, update, view)

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
            Data.PeerTube.keywordList
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
        ([ Request.PeerTube.getVideoList
            Request.PeerTube.emptyVideoListParams
            session.peerTubeURL
            RecentVideoListReceived
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


view : Session -> Model -> Page.Common.Components.Document Msg
view { staticFiles, peerTubeURL } ({ title, search, recentVideoData, videoData } as model) =
    let
        viewRecentVideo =
            [ Page.Common.Video.viewCategory recentVideoData peerTubeURL "Nouveautés" ]

        viewVideoCategories =
            Data.PeerTube.keywordList
                |> List.map
                    (\( keyword, _ ) ->
                        let
                            videoListData =
                                Dict.get keyword videoData
                                    |> Maybe.withDefault Data.PeerTube.NotRequested
                        in
                        Page.Common.Video.viewCategory videoListData peerTubeURL keyword
                    )
    in
    { title = title
    , pageTitle = "Classe à 12 en vidéo"
    , pageSubTitle = "Échangeons nos pratiques en toute simplicité !"
    , body =
        viewRecentVideo
            ++ viewVideoCategories
    }

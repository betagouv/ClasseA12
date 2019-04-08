module Page.Search exposing (Model, Msg(..), init, update, view)

import Data.PeerTube
import Data.Session exposing (Session)
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
    , keyword : String
    , videoListData : Data.PeerTube.RemoteData (List Data.PeerTube.Video)
    }


type Msg
    = VideoListReceived String (Result Http.Error (List Data.PeerTube.Video))


init : Maybe String -> Session -> ( Model, Cmd Msg )
init search session =
    case search of
        Nothing ->
            ( { title = "Liste des vidéos récentes"
              , keyword = "Nouveautés"
              , videoListData = Data.PeerTube.Requested
              }
            , Request.PeerTube.getRecentVideoList session.peerTubeURL (VideoListReceived "Nouveautés")
            )

        Just keyword ->
            ( { title = "Liste des vidéos dans la catégorie " ++ keyword
              , keyword = keyword
              , videoListData = Data.PeerTube.Requested
              }
            , Request.PeerTube.getVideoList keyword session.peerTubeURL (VideoListReceived keyword)
            )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        VideoListReceived keyword (Ok videoList) ->
            ( { model | videoListData = Data.PeerTube.Received videoList }
            , Cmd.none
            )

        VideoListReceived keyword (Err error) ->
            ( { model | videoListData = Data.PeerTube.Failed "Échec de la récupération des vidéos" }
            , Cmd.none
            )


view : Session -> Model -> ( String, List (H.Html Msg) )
view { staticFiles, peerTubeURL } ({ title, videoListData, keyword } as model) =
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
                    [ H.text title ]
                ]
            ]
      , H.div [ HA.class "main" ]
            (case videoListData of
                Data.PeerTube.NotRequested ->
                    []

                Data.PeerTube.Requested ->
                    [ H.section [ HA.class "section section-grey cards" ]
                        [ H.div [ HA.class "container" ]
                            [ H.div [ HA.class "row" ]
                                [ H.h1 [] [ H.text keyword ]
                                , H.text "Chargement des vidéos..."
                                ]
                            ]
                        ]
                    ]

                Data.PeerTube.Received videoList ->
                    viewVideoList keyword peerTubeURL videoList

                Data.PeerTube.Failed error ->
                    [ H.section [ HA.class "section section-white" ]
                        [ H.div [ HA.class "container" ]
                            [ H.text error ]
                        ]
                    ]
            )
      ]
    )


viewVideoList :
    String
    -> String
    -> List Data.PeerTube.Video
    -> List (H.Html Msg)
viewVideoList title peerTubeURL videoList =
    let
        videoCards =
            if videoList /= [] then
                videoList
                    |> List.map (\video -> viewPublicVideo peerTubeURL video)

            else
                [ H.text "Aucune vidéo pour le moment" ]
    in
    [ H.section [ HA.class "section section-grey cards" ]
        [ H.div [ HA.class "container" ]
            [ H.div [ HA.class "row" ]
                [ H.h1 [] [ H.text title ]
                , H.a [ HA.href "#" ] [ H.text "Afficher plus de vidéos" ]
                ]
            , H.div [ HA.class "row" ]
                videoCards
            ]
        ]
    ]


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
        , Page.Common.Video.details video
        , Page.Common.Video.keywords video.tags
        ]

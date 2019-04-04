module Page.Home exposing (Model, Msg(..), init, update, view)

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
import Set
import Task
import Time


type alias Model =
    { title : String
    , search : String
    , videoData : Data.PeerTube.RemoteData (List Data.PeerTube.Video)
    }


type Msg
    = UpdateSearch String
    | VideoListReceived (Result Http.Error (List Data.PeerTube.Video))


init : Session -> ( Model, Cmd Msg )
init session =
    ( { title = "Liste des vidéos"
      , search = ""
      , videoData = Data.PeerTube.Requested
      }
    , Request.PeerTube.getVideoList session.peerTubeURL VideoListReceived
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        UpdateSearch newSearch ->
            ( { model | search = newSearch }, Cmd.none )

        VideoListReceived (Ok videoList) ->
            ( { model | videoData = Data.PeerTube.Received videoList }
            , Cmd.none
            )

        VideoListReceived (Err error) ->
            ( { model | videoData = Data.PeerTube.Failed "Échec de la récupération des vidéos" }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view { staticFiles, peerTubeURL } ({ title, search, videoData } as model) =
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
      , H.div [ HA.class "main" ]
            (case videoData of
                Data.PeerTube.NotRequested ->
                    []

                Data.PeerTube.Requested ->
                    [ H.section [ HA.class "section section-white" ]
                        [ H.div [ HA.class "container" ]
                            [ H.text "Chargement des vidéos..." ]
                        ]
                    ]

                Data.PeerTube.Received videoList ->
                    viewVideoList peerTubeURL model videoList

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
    -> { a | search : String }
    -> List Data.PeerTube.Video
    -> List (H.Html Msg)
viewVideoList peerTubeURL { search } videoList =
    let
        videoCards =
            if videoList /= [] then
                videoList
                    |> List.map (\video -> viewPublicVideo peerTubeURL video)

            else
                [ H.text "Pas de vidéos trouvée" ]
    in
    [ H.section [ HA.class "section section-white" ]
        [ H.div [ HA.class "container" ]
            [ H.div
                [ HA.class "form__group light-background" ]
                [ H.label [ HA.for "search" ]
                    [ H.text "Filtrer par mot clé :" ]
                , H.div [ HA.class "search__group" ]
                    [ H.input
                        [ HA.id "keywords"
                        , HA.value search
                        , HA.placeholder "Lecture, Mathématiques, ..."
                        , Page.Common.Components.onChange UpdateSearch
                        ]
                        []
                    ]
                ]
            ]
        ]
    , H.section [ HA.class "section section-grey cards" ]
        [ H.div [ HA.class "container" ]
            [ H.div [ HA.class "row" ]
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

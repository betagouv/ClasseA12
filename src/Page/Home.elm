module Page.Home exposing (Model, Msg(..), init, update, view)

import Data.PeerTube
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA exposing (class)
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
            [ H.section [ HA.class "home__category wrapper", HA.id "playlist" ]
                [ H.h2 []
                    [ H.img
                        [ HA.src "%PUBLIC_URL%/images/icons/48x48/alaune_48_bicolore.svg"
                        , HA.alt ""
                        ]
                        []
                    , H.text "Les vidéos à la une"
                    ]
                , Page.Common.Video.viewVideoListData Route.Playlist playlistVideoData peerTubeURL
                , H.a [ Route.href Route.AllVideos ]
                    [ H.text "Voir toutes les vidéos"
                    ]
                ]
            ]
    in
    { title = title
    , pageTitle = "Classe à 12 en vidéo"
    , pageSubTitle = "Échangeons nos pratiques en toute simplicité !"
    , body =
        [ H.section [ HA.class "home__intro" ]
            [ H.div []
                [ H.img
                    [ HA.src "%PUBLIC_URL%/images/logos/classea12-dark.svg"
                    , HA.alt ""
                    , HA.class "logo"
                    ]
                    []
                , H.h1 []
                    [ H.text "La communauté vidéo"
                    , H.span [] [ H.text "des enseignants en classe à 12" ]
                    ]
                , H.p [] [ H.text "Chaque semaine, des enseignants de classe à 12 partagent leurs idées pédagogiques, ateliers, bonnes pratiques dans des formats vidéos courts." ]
                , H.a [ HA.class "btn", HA.href "" ] [ H.text "Découvrez les vidéos pédagogiques" ]
                , H.a [ HA.href "" ] [ H.text "Découvrez Classe à 12" ]
                ]
            , H.div [ HA.class "home__intro-logos" ]
                [ H.img
                    [ HA.src "%PUBLIC_URL%/images/logos/ecoleconfiance.png"
                    , HA.alt ""
                    , HA.class "logo-ecoleconfiance"
                    ]
                    []
                , H.img
                    [ HA.src "%PUBLIC_URL%/images/logos/110bis.svg"
                    , HA.alt ""
                    , HA.class "logo-110bis"
                    ]
                    []
                ]
            ]
        ]
            ++ viewPlaylistVideo
            ++ [ H.section [ HA.class "home__participate" ]
                    [ H.div [ class "wrapper" ]
                        [ H.h2 []
                            [ H.text "Et si vous participiez à cette belle aventure ?"
                            ]
                        , H.div [ class "home__participate-content" ]
                            [ H.div []
                                [ H.img [ HA.src "%PUBLIC_URL%/images/icons/48x48/gestion-de-classe_48_bicolore.svg" ] []
                                , H.h3 [] [ H.text "Une communauté d’enseignants, pour les enseignants" ]
                                , H.p [] [ H.text "Venenatis euismod sit sed habitant. Mattis vulputate bibendum commodo posuere turpis enim faucibus lacus. In praesent." ]
                                ]
                            , H.div []
                                [ H.img [ HA.src "%PUBLIC_URL%/images/icons/48x48/share_48_bicolore.svg" ] []
                                , H.h3 [] [ H.text "Un partage d’expériences, de pratiques et de bonnes idées" ]
                                , H.p [] [ H.text "Venenatis euismod sit sed habitant. Mattis vulputate bibendum commodo posuere turpis enim faucibus lacus. In praesent." ]
                                ]
                            , H.div []
                                [ H.img [ HA.src "%PUBLIC_URL%/images/icons/48x48/compte_48_bicolore.svg" ] []
                                , H.h3 [] [ H.text "Créez un compte totalement gratuit pour participer" ]
                                , H.p [] [ H.text "Venenatis euismod sit sed habitant. Mattis vulputate bibendum commodo posuere turpis enim faucibus lacus. In praesent." ]
                                ]
                            , H.div
                                [ HA.class "home__participate-photos" ]
                                [ H.div [ HA.class "about__image" ]
                                    [ H.img
                                        [ HA.src "%PUBLIC_URL%/images/photos/mobile.jpg"
                                        , HA.alt ""
                                        ]
                                        []
                                    ]
                                , H.div [ HA.class "about__image" ]
                                    [ H.img
                                        [ HA.src "%PUBLIC_URL%/images/photos/equipe.jpg"
                                        , HA.alt ""
                                        ]
                                        []
                                    ]
                                , H.div [ HA.class "about__image" ]
                                    [ H.img
                                        [ HA.src "%PUBLIC_URL%/images/photos/groupe.jpg"
                                        , HA.alt ""
                                        ]
                                        []
                                    ]
                                ]
                            ]
                        ]
                    , H.div [ HA.class "center-wrapper" ]
                        [ H.a [ class "btn btn--secondary", HA.href "#" ] [ H.text "Rejoignez la communauté" ]
                        ]
                    ]
               , H.section [ HA.class "home__category" ]
                    [ H.div [ class "wrapper" ]
                        [ H.h2 []
                            [ H.img [ HA.src "%PUBLIC_URL%/images/icons/48x48/alaune_48_bicolore.svg" ] []
                            , H.text "L’actualité de Classe à 12"
                            ]
                        ]
                    ]
               ]
    }

module Page.Home exposing (Model, Msg(..), init, update, view)

import Data.News
import Data.PeerTube
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA exposing (class)
import Http
import Page.AllNews exposing (viewPost)
import Page.Common.Components
import Page.Common.Video
import RemoteData exposing (RemoteData(..), WebData)
import Request.News exposing (getPostList)
import Request.PeerTube
import Route


type alias Model =
    { title : String
    , playlistVideoData : Data.PeerTube.RemoteData (List Data.PeerTube.Video)
    , postList : WebData (List Data.News.Post)
    }


type Msg
    = PlaylistVideoListReceived (Result Http.Error ( String, List Data.PeerTube.Video ))
    | PostListReceived (WebData (List Data.News.Post))


init : Session -> ( Model, Cmd Msg )
init session =
    ( { title = "Échangeons nos pratiques pédagogiques en vidéo"
      , playlistVideoData = Data.PeerTube.Requested
      , postList = Loading
      }
    , Cmd.batch
        [ Request.PeerTube.getPlaylistVideoList
            "devoirsfaits"
            Request.PeerTube.emptyVideoListParams
            session.peerTubeURL
            PlaylistVideoListReceived
        , getPostList PostListReceived
        ]
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

        PostListReceived data ->
            ( { model | postList = data }, Cmd.none )


view : Session -> Model -> Page.Common.Components.Document Msg
view { peerTubeURL, userRatedVideoIDs } { title, playlistVideoData, postList } =
    { title = title
    , pageTitle = "Devoirs Faits en vidéo"
    , pageSubTitle = "Échangeons nos pratiques en toute simplicité !"
    , body =
        [ viewHeader
        , viewPlaylistVideo peerTubeURL userRatedVideoIDs playlistVideoData
        , viewParticipate
        , viewNews postList
        ]
    }


viewHeader : H.Html Msg
viewHeader =
    H.section [ HA.class "home__intro" ]
        [ H.div []
            [ H.img
                [ HA.src "%PUBLIC_URL%/images/logos/devoirsfaits-dark.svg"
                , HA.alt ""
                , HA.class "logo"
                ]
                []
            , H.h1 []
                [ H.text "La communauté vidéo"
                , H.span [] [ H.text "du dispositif devoirs faits" ]
                ]
            , H.p [] [ H.text "Chaque semaine, des accompagnateurs aux devoirs partagent leurs idées pédagogiques, ateliers, bonnes pratiques dans des formats vidéos courts." ]
            , H.a [ HA.class "btn", Route.href Route.AllVideos ] [ H.text "Découvrez les vidéos pédagogiques" ]
            , H.a [ Route.href Route.About ] [ H.text "Découvrez Devoirs Faits" ]
            ]
        , H.div [ HA.class "home__intro-logos" ]
            [ H.img
                [ HA.src "%PUBLIC_URL%/images/logos/ecoleconfiance.svg"
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


viewPlaylistVideo : String -> List Data.PeerTube.VideoID -> Data.PeerTube.RemoteData (List Data.PeerTube.Video) -> H.Html Msg
viewPlaylistVideo peerTubeURL userRatedVideoIDs playlistVideoData =
    H.section [ HA.class "home__category wrapper", HA.id "playlist" ]
        [ H.h2 []
            [ H.img
                [ HA.src "%PUBLIC_URL%/images/icons/48x48/alaune_48_bicolore.svg"
                , HA.alt ""
                ]
                []
            , H.text "Les vidéos à la une"
            ]
        , Page.Common.Video.viewVideoListData Route.Playlist playlistVideoData peerTubeURL userRatedVideoIDs
        , H.a [ Route.href Route.AllVideos ]
            [ H.text "Voir toutes les vidéos"
            ]
        ]


viewParticipate : H.Html Msg
viewParticipate =
    H.section [ HA.class "home__participate" ]
        [ H.div [ class "wrapper" ]
            [ H.h2 []
                [ H.text "Et si vous participiez à cette belle aventure ?"
                ]
            , H.div [ class "home__participate-content" ]
                [ H.div []
                    [ H.img [ HA.src "%PUBLIC_URL%/images/icons/48x48/gestion-de-classe_48_bicolore.svg" ] []
                    , H.h3 [] [ H.text "Une communauté d’enseignants, pour les enseignants" ]
                    ]
                , H.div []
                    [ H.img [ HA.src "%PUBLIC_URL%/images/icons/48x48/share_48_bicolore.svg" ] []
                    , H.h3 [] [ H.text "Un partage d’expériences, de pratiques et de bonnes idées" ]
                    ]
                , H.div []
                    [ H.img [ HA.src "%PUBLIC_URL%/images/icons/48x48/compte_48_bicolore.svg" ] []
                    , H.h3 [] [ H.text "Créez un compte totalement gratuit pour participer" ]
                    ]
                , H.div
                    [ HA.class "home__participate-photos" ]
                    [ H.div [ HA.class "about__image" ]
                        [ H.img
                            [ HA.src "%PUBLIC_URL%/images/photos/photo_01.jpg"
                            , HA.alt ""
                            ]
                            []
                        ]
                    , H.div [ HA.class "about__image" ]
                        [ H.img
                            [ HA.src "%PUBLIC_URL%/images/photos/photo_02.jpg"
                            , HA.alt ""
                            ]
                            []
                        ]
                    , H.div [ HA.class "about__image" ]
                        [ H.img
                            [ HA.src "%PUBLIC_URL%/images/photos/photo_03.jpg"
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


viewNews : WebData (List Data.News.Post) -> H.Html Msg
viewNews postList =
    H.section [ HA.class "home__category wrapper" ]
        [ H.h2 []
            [ H.img [ HA.src "%PUBLIC_URL%/images/icons/48x48/alaune_48_bicolore.svg" ] []
            , H.text "L’actualité de Devoirs Faits"
            ]
        , case postList of
            Loading ->
                H.text "Chargement en cours..."

            Success posts ->
                H.div [ HA.class "news" ]
                    (posts
                        |> List.take 2
                        |> List.map viewPost
                    )

            Failure _ ->
                H.text "Erreur lors du chargement des actualités"

            NotAsked ->
                H.text "Erreur"
        , H.a [ Route.href Route.AllNews ]
            [ H.text "Voir toutes les actualités"
            ]
        ]

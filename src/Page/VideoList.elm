module Page.VideoList exposing (Model, Msg(..), init, update, view)

import Data.PeerTube
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Http
import Page.Common.Components
import Page.Common.Notifications as Notifications
import Page.Common.Video
import Request.PeerTube
import Route
import Url


type alias Model =
    { title : String
    , query : Route.VideoListQuery
    , videoListData : Data.PeerTube.RemoteData (List Data.PeerTube.Video)
    , videoListParams : Request.PeerTube.VideoListParams
    , playlistTitle : String
    , loadMoreState : Page.Common.Components.ButtonState
    , notifications : Notifications.Model
    }


type Msg
    = VideoListReceived (Result Http.Error (List Data.PeerTube.Video))
    | PlaylistVideoListReceived (Result Http.Error ( String, List Data.PeerTube.Video ))
    | LoadMore
    | NotificationMsg Notifications.Msg


init : Route.VideoListQuery -> Session -> ( Model, Cmd Msg )
init query session =
    let
        emptyVideoListParams =
            Request.PeerTube.emptyVideoListParams

        videoListParams : Request.PeerTube.VideoListParams
        videoListParams =
            { emptyVideoListParams | count = 20 }
    in
    case query of
        Route.Latest ->
            ( { title = "Liste des vidéos récentes"
              , query = Route.Latest
              , videoListData = Data.PeerTube.Requested
              , videoListParams = videoListParams
              , playlistTitle = ""
              , loadMoreState = Page.Common.Components.Loading
              , notifications = Notifications.init
              }
            , Request.PeerTube.getVideoList videoListParams session.peerTubeURL VideoListReceived
            )

        Route.Playlist ->
            ( { title = "Liste des vidéos de la playlist"
              , query = Route.Playlist
              , videoListData = Data.PeerTube.Requested
              , videoListParams = videoListParams
              , playlistTitle = ""
              , loadMoreState = Page.Common.Components.Loading
              , notifications = Notifications.init
              }
            , Request.PeerTube.getPlaylistVideoList "classea12" videoListParams session.peerTubeURL PlaylistVideoListReceived
            )

        Route.Keyword keyword ->
            let
                decoded =
                    keyword
                        |> Url.percentDecode
                        |> Maybe.withDefault ""

                paramsForKeyword =
                    videoListParams |> Request.PeerTube.withKeyword keyword
            in
            ( { title = "Liste des vidéos dans la catégorie " ++ decoded
              , query = Route.Keyword decoded
              , videoListData = Data.PeerTube.Requested
              , videoListParams = paramsForKeyword
              , playlistTitle = ""
              , loadMoreState = Page.Common.Components.Loading
              , notifications = Notifications.init
              }
            , Request.PeerTube.getVideoList
                paramsForKeyword
                session.peerTubeURL
                VideoListReceived
            )

        Route.Search search ->
            let
                decoded =
                    search
                        |> Url.percentDecode
                        |> Maybe.withDefault ""

                paramsForSearch =
                    { videoListParams | search = search }
            in
            ( { title = "Liste des vidéos pour la recherche " ++ decoded
              , query = Route.Search decoded
              , videoListData = Data.PeerTube.Requested
              , videoListParams = paramsForSearch
              , playlistTitle = ""
              , loadMoreState = Page.Common.Components.Loading
              , notifications = Notifications.init
              }
            , Request.PeerTube.getVideoList
                paramsForSearch
                session.peerTubeURL
                VideoListReceived
            )

        Route.Favorites profile ->
            let
                decoded =
                    profile
                        |> Url.percentDecode
                        |> Maybe.withDefault ""
            in
            ( { title = "Les vidéos favorites de " ++ decoded
              , query = Route.Favorites decoded
              , videoListData = Data.PeerTube.Requested
              , videoListParams = videoListParams
              , playlistTitle = ""
              , loadMoreState = Page.Common.Components.Loading
              , notifications = Notifications.init
              }
            , Request.PeerTube.getPlaylistVideoList
                profile
                videoListParams
                session.peerTubeURL
                PlaylistVideoListReceived
            )

        Route.Published profile ->
            let
                decoded =
                    profile
                        |> Url.percentDecode
                        |> Maybe.withDefault ""
            in
            ( { title = "Les vidéos publiées par " ++ decoded
              , query = Route.Published decoded
              , videoListData = Data.PeerTube.Requested
              , videoListParams = videoListParams
              , playlistTitle = ""
              , loadMoreState = Page.Common.Components.Loading
              , notifications = Notifications.init
              }
            , Request.PeerTube.userPublishedVideoList
                profile
                videoListParams
                session.peerTubeURL
                VideoListReceived
            )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        VideoListReceived (Ok videoList) ->
            let
                videoListData =
                    case model.videoListData of
                        Data.PeerTube.Received previousList ->
                            Data.PeerTube.Received (previousList ++ videoList)

                        _ ->
                            Data.PeerTube.Received videoList

                maybeDisabled =
                    if videoList == [] then
                        -- We didn't receive anything back from the API, there's no more videos to load
                        Page.Common.Components.Disabled

                    else
                        Page.Common.Components.NotLoading
            in
            ( { model
                | videoListData = videoListData
                , loadMoreState = maybeDisabled
              }
            , Cmd.none
            )

        VideoListReceived (Err _) ->
            ( { model
                | videoListData = Data.PeerTube.Failed "Échec de la récupération des vidéos"
                , notifications =
                    "Échec de la récupération de la vidéo"
                        |> Notifications.addError model.notifications
                , loadMoreState = Page.Common.Components.NotLoading
              }
            , Cmd.none
            )

        PlaylistVideoListReceived (Ok ( title, videoList )) ->
            let
                videoListData =
                    case model.videoListData of
                        Data.PeerTube.Received previousList ->
                            Data.PeerTube.Received (previousList ++ videoList)

                        _ ->
                            Data.PeerTube.Received videoList

                maybeDisabled =
                    if videoList == [] then
                        -- We didn't receive anything back from the API, there's no more videos to load
                        Page.Common.Components.Disabled

                    else
                        Page.Common.Components.NotLoading
            in
            ( { model
                | videoListData = videoListData
                , playlistTitle = title
                , loadMoreState = maybeDisabled
              }
            , Cmd.none
            )

        PlaylistVideoListReceived (Err _) ->
            ( { model
                | videoListData = Data.PeerTube.Failed "Échec de la récupération des vidéos"
                , notifications =
                    "Échec de la récupération de la vidéo"
                        |> Notifications.addError model.notifications
                , loadMoreState = Page.Common.Components.NotLoading
              }
            , Cmd.none
            )

        LoadMore ->
            let
                params =
                    model.videoListParams
                        |> Request.PeerTube.loadMoreVideos
            in
            ( { model
                | videoListParams = params
                , loadMoreState = Page.Common.Components.Loading
              }
            , case model.query of
                Route.Playlist ->
                    Request.PeerTube.getPlaylistVideoList
                        "classea12"
                        params
                        session.peerTubeURL
                        PlaylistVideoListReceived

                Route.Favorites profile ->
                    Request.PeerTube.getPlaylistVideoList
                        profile
                        params
                        session.peerTubeURL
                        PlaylistVideoListReceived

                Route.Published profile ->
                    Request.PeerTube.userPublishedVideoList
                        profile
                        params
                        session.peerTubeURL
                        VideoListReceived

                _ ->
                    Request.PeerTube.getVideoList
                        params
                        session.peerTubeURL
                        VideoListReceived
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }
            , Cmd.none
            )


view : Session -> Model -> Page.Common.Components.Document Msg
view { peerTubeURL } { title, videoListData, playlistTitle, query, notifications, loadMoreState } =
    { title = title
    , pageTitle =
        case query of
            Route.Search _ ->
                "Liste des vidéos"

            _ ->
                title
    , pageSubTitle =
        case query of
            Route.Search keyword ->
                "dans la catégorie " ++ keyword

            _ ->
                ""
    , body =
        [ H.map NotificationMsg (Notifications.view notifications)
        , case query of
            Route.Latest ->
                H.section [ HA.class "category", HA.id "latest" ]
                    [ H.div [ HA.class "home-title_wrapper" ]
                        [ H.h3 [ HA.class "home-title" ]
                            [ H.text "Les nouveautés"
                            ]
                        ]
                    , Page.Common.Video.viewVideoListData videoListData peerTubeURL
                    ]

            Route.Playlist ->
                let
                    playlistName =
                        if playlistTitle /= "" then
                            " : " ++ playlistTitle

                        else
                            ""
                in
                H.section [ HA.class "category", HA.id "playlist" ]
                    [ H.div [ HA.class "home-title_wrapper" ]
                        [ H.h3 [ HA.class "home-title" ]
                            [ H.text <| "La playlist de la semaine" ++ playlistName
                            ]
                        ]
                    , Page.Common.Video.viewVideoListData videoListData peerTubeURL
                    ]

            Route.Keyword keyword ->
                H.section [ HA.class "category", HA.id "keyword" ]
                    [ H.div [ HA.class "home-title_wrapper" ]
                        [ H.h3 [ HA.class "home-title" ]
                            [ H.text <| "Les vidéos dans la catégorie " ++ keyword
                            ]
                        ]
                    , Page.Common.Video.viewVideoListData videoListData peerTubeURL
                    ]

            Route.Search search ->
                H.section [ HA.class "category", HA.id "search" ]
                    [ H.div [ HA.class "home-title_wrapper" ]
                        [ H.h3 [ HA.class "home-title" ]
                            [ H.text <| "Les vidéos pour la recherche : " ++ search
                            ]
                        ]
                    , Page.Common.Video.viewVideoListData videoListData peerTubeURL
                    ]

            Route.Favorites profile ->
                H.section [ HA.class "category", HA.id "playlist" ]
                    [ H.div [ HA.class "home-title_wrapper" ]
                        [ H.h3 [ HA.class "home-title" ]
                            [ H.text <| "Les vidéos favorites de " ++ profile
                            ]
                        ]
                    , Page.Common.Video.viewVideoListData videoListData peerTubeURL
                    ]

            Route.Published profile ->
                H.section [ HA.class "category", HA.id "playlist" ]
                    [ H.div [ HA.class "home-title_wrapper" ]
                        [ H.h3 [ HA.class "home-title" ]
                            [ H.text <| "Les vidéos publiées par " ++ profile
                            ]
                        ]
                    , Page.Common.Video.viewVideoListData videoListData peerTubeURL
                    ]
        , case loadMoreState of
            Page.Common.Components.Disabled ->
                H.div [ HA.class "center-wrapper" ]
                    [ Page.Common.Components.button "Plus d'autres vidéos à afficher" loadMoreState Nothing
                    ]

            _ ->
                H.div [ HA.class "center-wrapper" ]
                    [ Page.Common.Components.button "Afficher plus de vidéos" loadMoreState (Just LoadMore)
                    ]
        ]
    }

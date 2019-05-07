module Page.Search exposing (Model, Msg(..), init, update, view)

import Data.PeerTube
import Data.Session exposing (Session)
import Html as H
import Http
import Page.Common.Components
import Page.Common.Notifications as Notifications
import Page.Common.Video
import Request.PeerTube
import Url


type alias Model =
    { title : String
    , keyword : String
    , videoListData : Data.PeerTube.RemoteData (List Data.PeerTube.Video)
    , videoListParams : Request.PeerTube.VideoListParams
    , loadMoreState : Page.Common.Components.ButtonState
    , notifications : Notifications.Model
    }


type Msg
    = VideoListReceived (Result Http.Error (List Data.PeerTube.Video))
    | LoadMore
    | NotificationMsg Notifications.Msg


init : Maybe String -> Session -> ( Model, Cmd Msg )
init search session =
    let
        emptyVideoListParams =
            Request.PeerTube.emptyVideoListParams

        videoListParams : Request.PeerTube.VideoListParams
        videoListParams =
            { emptyVideoListParams | count = 20 }
    in
    case search of
        Nothing ->
            ( { title = "Liste des vidéos récentes"
              , keyword = "Nouveautés"
              , videoListData = Data.PeerTube.Requested
              , videoListParams = videoListParams
              , loadMoreState = Page.Common.Components.Loading
              , notifications = Notifications.init
              }
            , Request.PeerTube.getVideoList videoListParams session.peerTubeURL VideoListReceived
            )

        Just keyword ->
            let
                decoded =
                    keyword
                        |> Url.percentDecode
                        |> Maybe.withDefault ""

                paramsForKeyword =
                    videoListParams |> Request.PeerTube.withKeyword keyword
            in
            ( { title = "Liste des vidéos dans la catégorie " ++ decoded
              , keyword = decoded
              , videoListData = Data.PeerTube.Requested
              , videoListParams = paramsForKeyword
              , loadMoreState = Page.Common.Components.Loading
              , notifications = Notifications.init
              }
            , Request.PeerTube.getVideoList
                paramsForKeyword
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
            , Request.PeerTube.getVideoList
                params
                session.peerTubeURL
                VideoListReceived
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }
            , Cmd.none
            )


view : Session -> Model -> Page.Common.Components.Document Msg
view { peerTubeURL } { title, videoListData, keyword, notifications, loadMoreState } =
    { title = title
    , pageTitle =
        if keyword == "Nouveautés" then
            title

        else
            "Liste des vidéos"
    , pageSubTitle =
        if keyword == "Nouveautés" then
            ""

        else
            "dans la catégorie " ++ keyword
    , body =
        [ H.map NotificationMsg (Notifications.view notifications)
        , Page.Common.Video.viewCategory videoListData peerTubeURL keyword
        , case loadMoreState of
            Page.Common.Components.Disabled ->
                Page.Common.Components.button "Plus d'autres vidéos à afficher" loadMoreState Nothing

            _ ->
                Page.Common.Components.button "Afficher plus de vidéos" loadMoreState (Just LoadMore)
        ]
    }

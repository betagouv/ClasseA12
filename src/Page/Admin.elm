module Page.Admin exposing (Model, Msg(..), init, update, view)

import Data.PeerTube
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Page.Common.Components
import Page.Common.Notifications as Notifications
import Page.Common.Video
import Request.PeerTube
import Route


type alias Model =
    { title : String
    , blacklistedVideoListData : Data.PeerTube.RemoteData (List Data.PeerTube.Video)

    -- TODO: better "link" the videoList and the blacklistedVideoListData
    -- The blacklistedVideoListData doesn't contain the full video data, that's why we send an extra
    -- request per video, and store them in the videoList.
    , videoList : List Data.PeerTube.Video
    , notifications : Notifications.Model
    , publishingVideos : PublishingVideos
    }


type alias PublishingVideos =
    List Data.PeerTube.Video


type Msg
    = BlacklistedVideoListFetched (Result Http.Error (List Data.PeerTube.Video))
    | VideoFetched (Result Http.Error Data.PeerTube.Video)
    | NotificationMsg Notifications.Msg
    | PublishVideo Data.PeerTube.Video
    | VideoPublished Data.PeerTube.Video (Result Http.Error String)


init : Session -> ( Model, Cmd Msg )
init session =
    let
        initialModel =
            { title = "Administration"
            , blacklistedVideoListData = Data.PeerTube.NotRequested
            , videoList = []
            , notifications = Notifications.init
            , publishingVideos = []
            }

        modelAndCommands =
            case session.userToken of
                Just userToken ->
                    let
                        username =
                            session.userInfo
                                |> Maybe.map .username
                                |> Maybe.withDefault ""
                    in
                    if Data.Session.isPeerTubeLoggedIn session.userInfo && username == "classea12" then
                        ( { initialModel
                            | blacklistedVideoListData = Data.PeerTube.Requested
                          }
                        , Request.PeerTube.getBlacklistedVideoList userToken session.peerTubeURL BlacklistedVideoListFetched
                        )

                    else
                        ( initialModel, Cmd.none )

                Nothing ->
                    ( initialModel, Cmd.none )
    in
    modelAndCommands


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        BlacklistedVideoListFetched (Ok videoList) ->
            ( { model | blacklistedVideoListData = Data.PeerTube.Received videoList }
            , videoList
                |> List.map
                    (\blacklistedVideo ->
                        Request.PeerTube.getVideo blacklistedVideo.uuid session.userToken session.peerTubeURL VideoFetched
                    )
                |> Cmd.batch
            )

        BlacklistedVideoListFetched (Err error) ->
            ( { model
                | blacklistedVideoListData = Data.PeerTube.Failed "Erreur lors de la récupération des vidéos à modérer"
                , notifications =
                    Notifications.addError model.notifications "Erreur lors de la récupération des vidéos à modérer"
              }
            , Cmd.none
            )

        VideoFetched (Ok video) ->
            ( { model
                | videoList =
                    (video
                        :: model.videoList
                    )
                        |> List.sortBy .publishedAt
                        |> List.reverse
              }
            , Cmd.none
            )

        VideoFetched (Err error) ->
            ( { model
                | notifications =
                    Notifications.addError model.notifications "Erreur lors de la récupération d'une vidéo "
              }
            , Cmd.none
            )

        PublishVideo video ->
            case session.userToken of
                Just userToken ->
                    ( { model | publishingVideos = video :: model.publishingVideos }
                    , Request.PeerTube.publishVideo video userToken session.peerTubeURL (VideoPublished video)
                    )

                Nothing ->
                    ( model, Cmd.none )

        VideoPublished video (Ok _) ->
            let
                publishingVideos =
                    model.publishingVideos
                        |> List.filter ((/=) video)

                videoList =
                    model.videoList
                        |> List.filter ((/=) video)
            in
            ( { model
                | publishingVideos = publishingVideos
                , videoList = videoList
              }
            , Cmd.none
            )

        VideoPublished _ (Err error) ->
            ( { model
                | notifications =
                    Notifications.addError model.notifications "Erreur lors de la publication de la vidéo"
              }
            , Cmd.none
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }, Cmd.none )


view : Session -> Model -> Page.Common.Components.Document Msg
view { peerTubeURL, userInfo } { title, notifications, blacklistedVideoListData, publishingVideos, videoList } =
    let
        username =
            userInfo
                |> Maybe.map .username
                |> Maybe.withDefault ""
    in
    { title = title
    , pageTitle = title
    , pageSubTitle = "Modération des vidéos"
    , body =
        [ H.map NotificationMsg (Notifications.view notifications)
        , if Data.Session.isPeerTubeLoggedIn userInfo then
            if username == "classea12" then
                case blacklistedVideoListData of
                    Data.PeerTube.Received blacklistedVideoList ->
                        H.section [ HA.class "section section-grey cards" ]
                            [ H.div [ HA.class "container" ]
                                (viewVideoList
                                    publishingVideos
                                    videoList
                                    peerTubeURL
                                )
                            ]

                    _ ->
                        H.div [ HA.class "section section-white" ]
                            [ H.div [ HA.class "container" ]
                                [ H.text "Chargement des vidéos en cours..." ]
                            ]

            else
                H.div [ HA.class "section section-white" ]
                    [ H.div [ HA.class "container" ]
                        [ H.text "Cette page est réservée aux administrateurs" ]
                    ]

          else
            Page.Common.Components.viewConnectNow "Pour accéder à cette page veuillez vous " "connecter"
        ]
    }


viewVideoList : PublishingVideos -> List Data.PeerTube.Video -> String -> List (H.Html Msg)
viewVideoList publishingVideos videoList peerTubeURL =
    videoList
        |> List.map (viewVideo publishingVideos peerTubeURL)


viewVideo : PublishingVideos -> String -> Data.PeerTube.Video -> H.Html Msg
viewVideo publishingVideos peerTubeURL video =
    let
        buttonState =
            if List.member video publishingVideos then
                Page.Common.Components.Loading

            else
                Page.Common.Components.NotLoading

        publishNode =
            Page.Common.Components.button "Publier cette vidéo" buttonState (Just <| PublishVideo video)
    in
    H.div []
        [ H.div
            [ HA.class "section section-white" ]
            [ H.div [ HA.class "container" ]
                [ Page.Common.Video.playerForVideo video peerTubeURL
                , Page.Common.Video.details video
                , Page.Common.Video.keywords video.tags
                , publishNode
                ]
            ]
        , H.br [] []
        ]

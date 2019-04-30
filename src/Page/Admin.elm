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
    , blacklistedVideoListData : Data.PeerTube.RemoteData (List Data.PeerTube.BlacklistedVideo)
    , notifications : Notifications.Model
    , publishingVideos : PublishingVideos
    }


type alias PublishingVideos =
    List Data.PeerTube.BlacklistedVideo


type Msg
    = NoOp
    | VideoListFetched (Result Http.Error (List Data.PeerTube.BlacklistedVideo))
    | NotificationMsg Notifications.Msg
    | PublishVideo Data.PeerTube.BlacklistedVideo
    | VideoPublished Data.PeerTube.BlacklistedVideo (Result Http.Error String)


init : Session -> ( Model, Cmd Msg )
init session =
    let
        initialModel =
            { title = "Administration"
            , blacklistedVideoListData = Data.PeerTube.NotRequested
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
                        , Request.PeerTube.getBlacklistedVideoList userToken.access_token session.peerTubeURL VideoListFetched
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
        NoOp ->
            ( model, Cmd.none )

        VideoListFetched (Ok videoList) ->
            ( { model | blacklistedVideoListData = Data.PeerTube.Received videoList }
            , Cmd.none
            )

        VideoListFetched (Err error) ->
            ( { model
                | blacklistedVideoListData = Data.PeerTube.Failed "Erreur lors de la récupération des vidéos à modérer"
                , notifications =
                    Notifications.addError model.notifications "Erreur lors de la récupération des vidéos à modérer"
              }
            , Cmd.none
            )

        PublishVideo blacklistedVideo ->
            case session.userToken of
                Just userToken ->
                    ( { model | publishingVideos = blacklistedVideo :: model.publishingVideos }
                    , Request.PeerTube.publishVideo blacklistedVideo userToken.access_token session.peerTubeURL (VideoPublished blacklistedVideo)
                    )

                Nothing ->
                    ( model, Cmd.none )

        VideoPublished blacklistedVideo (Ok _) ->
            let
                blacklistedVideoListData =
                    case model.blacklistedVideoListData of
                        Data.PeerTube.Received videoList ->
                            videoList
                                |> List.filter ((/=) blacklistedVideo)
                                |> Data.PeerTube.Received

                        data ->
                            data

                publishingVideos =
                    model.publishingVideos
                        |> List.filter ((/=) blacklistedVideo)
            in
            ( { model
                | blacklistedVideoListData = blacklistedVideoListData
                , publishingVideos = publishingVideos
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
view { peerTubeURL, userInfo } { title, notifications, blacklistedVideoListData, publishingVideos } =
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
                    Data.PeerTube.Received videoList ->
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


viewVideoList : PublishingVideos -> List Data.PeerTube.BlacklistedVideo -> String -> List (H.Html Msg)
viewVideoList publishingVideos blacklistedVideoList peerTubeURL =
    [ H.div [ HA.class "row" ]
        (blacklistedVideoList
            |> List.map (viewVideo publishingVideos peerTubeURL)
        )
    ]


viewVideo : PublishingVideos -> String -> Data.PeerTube.BlacklistedVideo -> H.Html Msg
viewVideo publishingVideos peerTubeURL blacklistedVideo =
    let
        buttonState =
            if List.member blacklistedVideo publishingVideos then
                Page.Common.Components.Loading

            else
                Page.Common.Components.NotLoading

        publishNode =
            Page.Common.Components.button "Publier cette vidéo" buttonState (Just <| PublishVideo blacklistedVideo)

        video =
            blacklistedVideo.video
    in
    H.div
        [ HA.class "card" ]
        [ H.div
            [ HA.class "card__cover" ]
            [ H.a [ Route.href <| Route.Video video.uuid video.name ] [ H.text video.name ]
            ]
        , Page.Common.Video.details video
        , Page.Common.Video.keywords video.tags
        , publishNode
        ]

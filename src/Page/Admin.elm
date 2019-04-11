module Page.Admin exposing (Model, Msg(..), init, update, view)

import Data.Kinto exposing (DeletedRecord, Video, VideoList, VideoListData)
import Data.Session exposing (Session, UserData, decodeUserData, emptyUserData, encodeUserData)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Kinto
import Page.Common.Components
import Page.Common.Notifications as Notifications
import Page.Common.Video
import Ports
import Request.Kinto exposing (authClient)
import Request.KintoProfile
import Request.KintoUpcoming
import Request.KintoVideo
import Task
import Time
import Url


type alias Model =
    { title : String
    , videoListData : VideoListData
    , videoAuthorsData : Data.Kinto.KintoData Data.Kinto.ProfileList
    , notifications : Notifications.Model
    , publishingVideos : PublishingVideos
    , activeVideo : Maybe Data.Kinto.Video
    }


type alias PublishingVideos =
    List Video


type Msg
    = NoOp
    | VideoListFetched (Result Kinto.Error VideoList)
    | VideoAuthorsFetched (Result Kinto.Error Data.Kinto.ProfileList)
    | NotificationMsg Notifications.Msg
    | GetTimestamp Video
    | PublishVideo Video Time.Posix
    | VideoPublished (Result Kinto.Error Video)
    | VideoRemoved Video (Result Kinto.Error DeletedRecord)
    | ToggleVideo Data.Kinto.Video


init : Session -> ( Model, Cmd Msg )
init session =
    let
        initialModel =
            { title = "Administration"
            , videoListData = Data.Kinto.NotRequested
            , videoAuthorsData = Data.Kinto.NotRequested
            , notifications = Notifications.init
            , publishingVideos = []
            , activeVideo = Nothing
            }

        modelAndCommands =
            if Data.Session.isLoggedIn session.userData && session.userData.username == "classea12admin" then
                let
                    client =
                        authClient session.kintoURL session.userData.username session.userData.password
                in
                ( { initialModel
                    | videoListData = Data.Kinto.Requested
                  }
                , Request.KintoUpcoming.getVideoList client VideoListFetched
                )

            else
                ( initialModel, Cmd.none )
    in
    modelAndCommands


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        VideoListFetched (Ok videoList) ->
            let
                authorIDs =
                    videoList.objects
                        |> List.map (\video -> video.profile)
            in
            ( { model | videoListData = Data.Kinto.Received videoList }
            , Request.KintoProfile.getProfileList session.kintoURL authorIDs VideoAuthorsFetched
            )

        VideoListFetched (Err err) ->
            ( { model
                | videoListData = Data.Kinto.Failed err
                , notifications =
                    Kinto.errorToString err
                        |> Notifications.addError model.notifications
              }
            , Cmd.none
            )

        VideoAuthorsFetched (Ok videoAuthors) ->
            ( { model | videoAuthorsData = Data.Kinto.Received videoAuthors }, Cmd.none )

        VideoAuthorsFetched (Err err) ->
            ( { model
                | videoAuthorsData = Data.Kinto.Failed err
                , notifications =
                    Kinto.errorToString err
                        |> Notifications.addError model.notifications
              }
            , Cmd.none
            )

        GetTimestamp video ->
            ( { model | publishingVideos = model.publishingVideos ++ [ video ] }
            , Task.perform (PublishVideo video) Time.now
            )

        PublishVideo video timestamp ->
            let
                client =
                    authClient session.kintoURL session.userData.username session.userData.password

                timestampedVideo =
                    { video | publish_date = timestamp }
            in
            ( model
            , Request.KintoVideo.publishVideo timestampedVideo client VideoPublished
            )

        VideoPublished (Ok video) ->
            let
                client =
                    authClient session.kintoURL session.userData.username session.userData.password
            in
            ( model
            , Request.KintoUpcoming.removeVideo video client (VideoRemoved video)
            )

        VideoPublished (Err err) ->
            ( { model
                | notifications =
                    Kinto.errorToString err
                        |> Notifications.addError model.notifications
              }
            , Cmd.none
            )

        VideoRemoved video (Ok deletedRecord) ->
            let
                videoListData =
                    case model.videoListData of
                        Data.Kinto.Received videos ->
                            videos.objects
                                -- We remove the video from the list of upcoming videos, as it's just been deleted
                                |> List.filter (\publishedVideo -> publishedVideo.id /= video.id)
                                -- Update the "objects" field in the Kinto.Pager record with the filtered list of videos
                                |> (\videoList -> { videos | objects = videoList })
                                |> Data.Kinto.Received

                        kintoData ->
                            kintoData

                publishingVideos =
                    model.publishingVideos
                        |> List.filter ((/=) video)
            in
            ( { model
                | videoListData = videoListData
                , publishingVideos = publishingVideos
              }
            , Cmd.none
            )

        VideoRemoved video (Err err) ->
            ( { model
                | notifications =
                    Kinto.errorToString err
                        |> Notifications.addError model.notifications
              }
            , Cmd.none
            )

        ToggleVideo video ->
            let
                activeVideo =
                    case model.activeVideo of
                        -- Toggle the active video
                        Just v ->
                            Nothing

                        Nothing ->
                            Just video
            in
            ( { model | activeVideo = activeVideo }, Cmd.none )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view { timezone, userData, staticFiles } { title, notifications, videoListData, videoAuthorsData, publishingVideos, activeVideo } =
    ( title
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src staticFiles.logo_ca12, HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "Administration" ]
                , H.p [] [ H.text "Modération des vidéos et des commentaires" ]
                ]
            ]
      , H.div [ HA.class "main" ]
            [ H.map NotificationMsg (Notifications.view notifications)
            , if Data.Session.isLoggedIn userData then
                if userData.username == "classea12admin" then
                    case videoListData of
                        Data.Kinto.Received videoList ->
                            H.section [ HA.class "section section-grey cards" ]
                                [ H.div [ HA.class "container" ]
                                    (viewVideoList
                                        timezone
                                        publishingVideos
                                        activeVideo
                                        videoList
                                        videoAuthorsData
                                    )
                                ]

                        _ ->
                            H.div [ HA.class "section section-white" ]
                                [ H.div [ HA.class "container" ]
                                    [ H.text "Chargement des vidéos et des contacts en cours..." ]
                                ]

                else
                    H.div [ HA.class "section section-white" ]
                        [ H.div [ HA.class "container" ]
                            [ H.text "Cette page est réservée aux administrateurs" ]
                        ]

              else
                Page.Common.Components.viewConnectNow "Pour accéder à cette page veuillez vous " "connecter"
            ]
      ]
    )


viewVideoList : Time.Zone -> PublishingVideos -> Maybe Data.Kinto.Video -> VideoList -> Data.Kinto.KintoData Data.Kinto.ProfileList -> List (H.Html Msg)
viewVideoList timezone publishingVideos activeVideo videoList videoAuthorsData =
    [ viewVideoModal ToggleVideo activeVideo
    , H.div [ HA.class "row" ]
        (videoList.objects
            |> List.map (viewVideo timezone publishingVideos videoAuthorsData)
        )
    ]


viewVideoModal : (Data.Kinto.Video -> Msg) -> Maybe Data.Kinto.Video -> H.Html Msg
viewVideoModal toggleVideo activeVideo =
    case activeVideo of
        Nothing ->
            H.div [] []

        Just video ->
            H.div
                [ HA.class "modal__backdrop is-active"
                , HE.onClick (toggleVideo video)
                ]
                [ H.div [ HA.class "modal" ] [ Page.Common.Video.player NoOp video.attachment ]
                , H.button [ HA.class "modal__close" ]
                    [ H.i [ HA.class "fas fa-times fa-2x" ] [] ]
                ]


viewVideo : Time.Zone -> PublishingVideos -> Data.Kinto.KintoData Data.Kinto.ProfileList -> Data.Kinto.Video -> H.Html Msg
viewVideo timezone publishingVideos videoAuthorsData video =
    let
        buttonState =
            if List.member video publishingVideos then
                Page.Common.Components.Loading

            else
                Page.Common.Components.NotLoading

        publishNode =
            -- Before publishing the video, get the timestamp (so we can use it as the publish_date)
            Page.Common.Components.button "Publier cette vidéo" buttonState (Just <| GetTimestamp video)

        profileData =
            case videoAuthorsData of
                Data.Kinto.Received videoAuthors ->
                    videoAuthors.objects
                        |> List.filter (\author -> author.id == video.profile)
                        |> List.head
                        |> Maybe.map Data.Kinto.Received
                        |> Maybe.withDefault Data.Kinto.NotRequested

                _ ->
                    Data.Kinto.NotRequested
    in
    H.div
        [ HA.class "card" ]
        [ H.div
            [ HA.class "card__cover" ]
            [ H.img
                [ HA.alt video.title
                , HA.src video.thumbnail
                , HE.onClick (ToggleVideo video)
                ]
                []
            ]
        , Page.Common.Video.kintoDetails timezone video profileData
        , Page.Common.Video.keywords video.keywords
        , publishNode
        ]

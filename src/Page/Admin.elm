module Page.Admin exposing (Model, Msg(..), init, update, view)

import Data.Kinto exposing (ContactList, ContactListData, DeletedRecord, Video, VideoList, VideoListData)
import Data.Session exposing (Session, UserData, decodeUserData, emptyUserData, encodeUserData)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Kinto
import Page.Common.Notifications as Notifications
import Page.Utils
import Ports
import Request.Kinto exposing (authClient)
import Request.KintoContact
import Request.KintoUpcoming
import Request.KintoVideo
import Route
import Time
import Url


type alias Model =
    { videoListData : VideoListData
    , contactListData : ContactListData
    , notifications : Notifications.Model
    , publishingVideos : PublishingVideos
    , activeVideo : Maybe Data.Kinto.Video
    }


type alias PublishingVideos =
    List Video


type Msg
    = VideoListFetched (Result Kinto.Error VideoList)
    | ContactListFetched (Result Kinto.Error ContactList)
    | NotificationMsg Notifications.Msg
    | PublishVideo Video
    | VideoPublished (Result Kinto.Error Video)
    | VideoRemoved Video (Result Kinto.Error DeletedRecord)
    | ToggleVideo Data.Kinto.Video


init : Session -> ( Model, Cmd Msg )
init session =
    let
        initialModel =
            { videoListData = Data.Kinto.NotRequested
            , contactListData = Data.Kinto.NotRequested
            , notifications = Notifications.init
            , publishingVideos = []
            , activeVideo = Nothing
            }

        modelAndCommands =
            if Data.Session.isLoggedIn session.userData then
                let
                    client =
                        authClient session.kintoURL session.userData.username session.userData.password
                in
                ( { initialModel
                    | videoListData = Data.Kinto.Requested
                    , contactListData = Data.Kinto.Requested
                  }
                , Cmd.batch
                    [ Request.KintoUpcoming.getVideoList client VideoListFetched
                    , Request.KintoContact.getContactList client ContactListFetched
                    ]
                )

            else
                ( initialModel, Cmd.none )
    in
    modelAndCommands


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        VideoListFetched (Ok videoList) ->
            ( { model | videoListData = Data.Kinto.Received videoList }, Cmd.none )

        VideoListFetched (Err err) ->
            ( { model
                | videoListData = Data.Kinto.Failed err
                , notifications =
                    Kinto.errorToString err
                        |> Notifications.addError model.notifications
              }
            , Cmd.none
            )

        ContactListFetched (Ok contactList) ->
            ( { model | contactListData = Data.Kinto.Received contactList }, Cmd.none )

        ContactListFetched (Err err) ->
            ( { model
                | contactListData = Data.Kinto.Failed err
                , notifications =
                    Kinto.errorToString err
                        |> Notifications.addError model.notifications
              }
            , Cmd.none
            )

        PublishVideo video ->
            let
                client =
                    authClient session.kintoURL session.userData.username session.userData.password
            in
            ( { model | publishingVideos = model.publishingVideos ++ [ video ] }
            , Request.KintoVideo.publishVideo video client VideoPublished
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
                                |> List.filter ((/=) video)
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
view { timezone, userData } { notifications, videoListData, contactListData, publishingVideos, activeVideo } =
    ( "Administration"
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src "/logo_ca12.png", HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "Administration" ]
                , H.p [] [ H.text "Modération des vidéos et des commentaires" ]
                ]
            ]
      , H.div [ HA.class "main" ]
            [ H.map NotificationMsg (Notifications.view notifications)
            , if Data.Session.isLoggedIn userData then
                case videoListData of
                    Data.Kinto.Received videoList ->
                        H.section [ HA.class "section section-grey cards" ]
                            [ H.div [ HA.class "container" ]
                                ([ H.div [ HA.class "form__group logout-button" ]
                                    [ downloadContacts contactListData ]
                                 ]
                                    ++ viewVideoList timezone publishingVideos activeVideo videoList
                                )
                            ]

                    _ ->
                        H.div [ HA.class "section section-white" ]
                            [ H.div [ HA.class "container" ]
                                [ H.text "Chargement des vidéos et des contacts en cours..." ]
                            ]

              else
                Page.Utils.viewConnectNow "Pour accéder à cette page veuillez vous " "connecter"
            ]
      ]
    )


viewVideoList : Time.Zone -> PublishingVideos -> Maybe Data.Kinto.Video -> VideoList -> List (H.Html Msg)
viewVideoList timezone publishingVideos activeVideo videoList =
    [ Page.Utils.viewVideoModal ToggleVideo activeVideo
    , H.div [ HA.class "row" ]
        (videoList.objects
            |> List.map (viewVideo timezone publishingVideos)
        )
    ]


viewVideo : Time.Zone -> PublishingVideos -> Data.Kinto.Video -> H.Html Msg
viewVideo timezone publishingVideos video =
    let
        buttonState =
            if List.member video publishingVideos then
                Page.Utils.Loading

            else
                Page.Utils.NotLoading

        publishNode =
            [ Page.Utils.button "Publier cette vidéo" buttonState (Just <| PublishVideo video) ]
    in
    Page.Utils.viewVideo timezone (ToggleVideo video) publishNode video


downloadContacts : Data.Kinto.ContactListData -> H.Html Msg
downloadContacts contactListData =
    case contactListData of
        Data.Kinto.Received contactList ->
            H.a
                [ contactListHref contactList
                , HA.download "contacts_infolettre.csv"
                ]
                [ H.text "Télécharger la liste des contacts infolettre" ]

        _ ->
            H.span [] []


contactListHref : ContactList -> H.Attribute msg
contactListHref contactList =
    let
        contactListAsCsvEntries =
            contactList.objects
                |> List.map
                    (\contact ->
                        contact.name ++ "," ++ contact.email
                    )

        csvLines =
            [ "Nom,Email" ] ++ contactListAsCsvEntries
    in
    csvLines
        |> String.join "\n"
        |> Url.percentEncode
        |> (++) "data:text/csv;charset=utf-8,"
        |> HA.href

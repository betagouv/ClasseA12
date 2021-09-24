module Page.Video exposing (Model, Msg(..), init, update, view)

import Browser.Dom as Dom
import Data.PeerTube
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import List.Extra
import Markdown
import Page.Common.Components as Components
import Page.Common.Dates as Dates
import Page.Common.Notifications as Notifications
import Page.Common.Progress
import Page.Common.Video
import Page.Common.XHR
import Ports
import Request.Files exposing (Attachment)
import Request.PeerTube
import Route
import Task
import Url exposing (Url)


type alias Model =
    { title : String
    , videoID : String
    , videoData : Data.PeerTube.RemoteData Data.PeerTube.Video
    , videoTitle : String
    , comments : Data.PeerTube.RemoteData (List Data.PeerTube.Comment)
    , comment : String
    , commentData : Data.PeerTube.RemoteData Data.PeerTube.Comment
    , refreshing : Bool
    , attachmentData : Data.PeerTube.RemoteData String
    , attachmentSelected : Bool
    , progress : Page.Common.Progress.Progress
    , attachmentList : List Attachment
    , relatedVideos : Data.PeerTube.RemoteData (List Data.PeerTube.Video)
    , numRelatedVideosToDisplay : Int
    , loadMoreState : Components.ButtonState
    , notifications : Notifications.Model
    , activeTab : Tab
    , deletedVideo : Data.PeerTube.RemoteData ()
    , displayDeleteModal : Bool
    , favoriteStatus : FavoriteStatus
    , togglingFavoriteStatus : Data.PeerTube.RemoteData ()
    }


type Tab
    = ContributionTab
    | RelatedVideosTab


type FavoriteStatus
    = Unknown
    | Favorite Data.PeerTube.FavoriteData
    | NotFavorite


type Msg
    = VideoReceived (Request.PeerTube.PeerTubeResult Data.PeerTube.Video)
    | ShareVideo String
    | CommentsReceived (Result Http.Error (List Data.PeerTube.Comment))
    | UpdateCommentForm String
    | AddComment
    | CommentAdded String (Request.PeerTube.PeerTubeResult Data.PeerTube.Comment)
    | CommentSelected String
    | AttachmentSelected
    | AttachmentSent Decode.Value
    | ProgressUpdated Decode.Value
    | AttachmentListReceived (Result (Maybe String) (List Attachment))
    | RelatedVideosReceived (Result Http.Error (List (List Data.PeerTube.Video)))
    | LoadMore
    | ActivateTab Tab
    | NotificationMsg Notifications.Msg
    | AskDeleteConfirmation
    | DiscardDeleteConfirmation
    | DeleteVideo Data.PeerTube.Video
    | VideoDeleted (Request.PeerTube.PeerTubeResult String)
    | FavoriteStatusReceived (Request.PeerTube.PeerTubeResult (Maybe Data.PeerTube.FavoriteData))
    | RemoveFromFavorite Data.PeerTube.FavoriteData
    | RemovedFromFavoriteReceived (Request.PeerTube.PeerTubeResult String)
    | AddToFavorite
    | AddedToFavoriteReceived (Request.PeerTube.PeerTubeResult Data.PeerTube.FavoriteData)
    | NoOp


numRelatedVideos : Int
numRelatedVideos =
    3


init : String -> String -> Session -> ( Model, Cmd Msg )
init videoID videoTitle session =
    let
        decodedVideoTitle =
            videoTitle
                |> Url.percentDecode
                |> Maybe.withDefault videoTitle

        title =
            "Vidéo : " ++ decodedVideoTitle
    in
    ( { title = title
      , videoID = videoID
      , videoData = Data.PeerTube.Requested
      , videoTitle = decodedVideoTitle
      , comments = Data.PeerTube.Requested
      , comment = ""
      , commentData = Data.PeerTube.NotRequested
      , refreshing = False
      , attachmentData = Data.PeerTube.NotRequested
      , attachmentSelected = False
      , progress = Page.Common.Progress.empty
      , attachmentList = []
      , relatedVideos = Data.PeerTube.NotRequested
      , numRelatedVideosToDisplay = numRelatedVideos
      , loadMoreState = Components.NotLoading
      , notifications = Notifications.init
      , activeTab = ContributionTab
      , deletedVideo = Data.PeerTube.NotRequested
      , displayDeleteModal = False
      , favoriteStatus = Unknown
      , togglingFavoriteStatus = Data.PeerTube.NotRequested
      }
    , Cmd.batch
        [ Request.PeerTube.getVideo videoID session.userToken session.peerTubeURL VideoReceived
        , Request.PeerTube.getVideoCommentList videoID session.peerTubeURL CommentsReceived
        , Request.Files.getVideoAttachmentList videoID session.filesURL AttachmentListReceived
        ]
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg, Maybe Data.Session.Msg )
update session msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none, Nothing )

        VideoReceived (Ok authResult) ->
            let
                video =
                    Request.PeerTube.extractResult authResult

                -- Request related videos: query the videos that have all the
                -- keywords, and then the ones which have one keyword in common.
                -- This will be something like [[foo, bar], [foo], [bar]]
                relatedVideosKeywordsToRequest =
                    List.foldl
                        (\keyword acc ->
                            -- Make sure we don't have duplicates, for exemple if there's a single keyword
                            if not (List.member [ keyword ] acc) then
                                [ keyword ] :: acc

                            else
                                acc
                        )
                        -- Start with the full list of keywords
                        [ video.tags ]
                        video.tags
                        -- We want the full list of keywords first, it's the most representative of related videos
                        |> List.reverse

                relatedVideosCommands =
                    relatedVideosKeywordsToRequest
                        |> List.map
                            (\keywords ->
                                let
                                    params =
                                        Request.PeerTube.withKeywords keywords Request.PeerTube.emptyVideoListParams
                                            |> Request.PeerTube.withCount 20
                                in
                                Request.PeerTube.videoListRequest params session.peerTubeURL
                                    -- Get the task ...
                                    |> Http.toTask
                            )
                        -- ... then make a single task from the list of tasks
                        |> Task.sequence
                        -- ... and finally transform that into a command
                        |> Task.attempt RelatedVideosReceived

                favoriteStatusCommand =
                    case session.userToken of
                        Just token ->
                            [ Request.PeerTube.getFavoriteStatus video.id token session.peerTubeURL FavoriteStatusReceived ]

                        Nothing ->
                            []
            in
            ( { model
                | videoData = Data.PeerTube.Received video
                , relatedVideos = Data.PeerTube.Requested
              }
            , Cmd.batch
                ([ scrollToComment session.url.fragment model
                 , relatedVideosCommands
                 ]
                    ++ favoriteStatusCommand
                )
            , Request.PeerTube.extractSessionMsg authResult
            )

        VideoReceived (Err authError) ->
            ( { model
                | videoData = Data.PeerTube.Failed "Échec de la récupération de la vidéo"
                , notifications =
                    "Échec de la récupération de la vidéo"
                        |> Notifications.addError model.notifications
              }
            , Cmd.none
            , Request.PeerTube.extractSessionMsgFromError authError
            )

        ShareVideo shareText ->
            ( model, Ports.navigatorShare shareText, Nothing )

        CommentsReceived (Ok comments) ->
            ( { model
                | comments = Data.PeerTube.Received comments
                , refreshing = False
              }
            , scrollToComment session.url.fragment model
            , Nothing
            )

        CommentsReceived (Err _) ->
            ( { model
                | comments = Data.PeerTube.Failed "Échec de la récupération des commentaires"
                , notifications =
                    "Échec de la récupération des commentaires"
                        |> Notifications.addError model.notifications
              }
            , Cmd.none
            , Nothing
            )

        UpdateCommentForm comment ->
            ( { model | comment = comment }, Cmd.none, Nothing )

        AddComment ->
            case session.userToken of
                Just userToken ->
                    ( { model | commentData = Data.PeerTube.Requested }
                    , Request.PeerTube.submitComment
                        model.comment
                        model.videoID
                        userToken
                        session.peerTubeURL
                        (CommentAdded userToken.access_token)
                    , Nothing
                    )

                Nothing ->
                    -- Profile not created yet: we shouldn't be there.
                    ( model, Cmd.none, Nothing )

        CommentAdded access_token (Ok authResult) ->
            let
                comment =
                    Request.PeerTube.extractResult authResult
            in
            if model.attachmentSelected then
                let
                    filePath =
                        "/" ++ model.videoID ++ "/" ++ String.fromInt comment.id ++ "/"

                    submitAttachmentData : Ports.SubmitAttachmentData
                    submitAttachmentData =
                        { nodeID = "attachment"
                        , filePath = filePath
                        , access_token = access_token
                        }
                in
                ( { model
                    | commentData = Data.PeerTube.Received comment
                    , attachmentData = Data.PeerTube.Requested
                  }
                  -- Upload the attachment
                , Ports.submitAttachment submitAttachmentData
                , Request.PeerTube.extractSessionMsg authResult
                )

            else
                ( { model
                    | commentData = Data.PeerTube.Received comment
                    , refreshing = True
                  }
                  -- Refresh the list of comments
                , Cmd.batch
                    [ Request.PeerTube.getVideoCommentList model.videoID session.peerTubeURL CommentsReceived
                    , Request.Files.getVideoAttachmentList model.videoID session.filesURL AttachmentListReceived
                    ]
                , Request.PeerTube.extractSessionMsg authResult
                )

        CommentAdded _ (Err authError) ->
            ( { model
                | commentData = Data.PeerTube.Failed "Échec de l'ajout du commentaire"
                , notifications =
                    "Échec de l'ajout du commentaire"
                        |> Notifications.addError model.notifications
              }
            , Cmd.none
            , Request.PeerTube.extractSessionMsgFromError authError
            )

        ProgressUpdated value ->
            let
                progress =
                    Decode.decodeValue Page.Common.Progress.decoder value
                        |> Result.withDefault Page.Common.Progress.empty
            in
            ( { model | progress = progress }
            , Cmd.none
            , Nothing
            )

        AttachmentSelected ->
            let
                comment =
                    if model.comment /= "" then
                        model.comment

                    else
                        "Pièce jointe"
            in
            ( { model
                | attachmentSelected = True
                , comment = comment
              }
            , Cmd.none
            , Nothing
            )

        AttachmentSent response ->
            let
                updatedModel =
                    { model
                        | comment = ""
                        , attachmentSelected = False
                        , progress = Page.Common.Progress.empty
                    }
            in
            case Decode.decodeValue Page.Common.XHR.decoder response of
                Ok (Page.Common.XHR.Success filePath) ->
                    ( { updatedModel
                        | refreshing = True
                        , attachmentData = Data.PeerTube.Received filePath
                      }
                      -- Refresh the list of comments (and then contributors)
                    , Cmd.batch
                        [ Request.PeerTube.getVideoCommentList model.videoID session.peerTubeURL CommentsReceived
                        , Request.Files.getVideoAttachmentList model.videoID session.filesURL AttachmentListReceived
                        ]
                    , Nothing
                    )

                Ok (Page.Common.XHR.BadStatus status _) ->
                    ( { updatedModel
                        | notifications =
                            "Échec de l'envoi du fichier"
                                |> Notifications.addError model.notifications
                        , attachmentData = Data.PeerTube.Failed "Échec de l'envoi du fichier"
                      }
                    , Cmd.none
                    , if status == 401 then
                        Just Data.Session.Logout

                      else
                        Nothing
                    )

                Err _ ->
                    ( { updatedModel
                        | notifications =
                            "Échec de l'envoi du fichier"
                                |> Notifications.addError model.notifications
                        , attachmentData = Data.PeerTube.Failed "Échec de l'envoi du fichier"
                      }
                    , Cmd.none
                    , Nothing
                    )

        CommentSelected commentID ->
            ( model
            , scrollToComment (Just commentID) model
            , Nothing
            )

        AttachmentListReceived (Ok attachmentList) ->
            ( { model | attachmentList = attachmentList }
            , Cmd.none
            , Nothing
            )

        AttachmentListReceived (Err error) ->
            let
                updatedModel =
                    case error of
                        Just errorMessage ->
                            { model
                                | notifications =
                                    errorMessage
                                        |> Notifications.addError model.notifications
                            }

                        Nothing ->
                            { model | attachmentList = [] }
            in
            ( updatedModel
            , Cmd.none
            , Nothing
            )

        RelatedVideosReceived (Ok videosLists) ->
            let
                newVideos =
                    videosLists
                        -- Transform the list of "video lists" into a flat list
                        |> List.concat
                        -- Remove the current video from the list of suggestions
                        |> List.filter (\video -> video.uuid /= model.videoID)
                        |> dedupVideos
            in
            ( { model | relatedVideos = Data.PeerTube.Received newVideos }
            , Cmd.none
            , Nothing
            )

        RelatedVideosReceived (Err _) ->
            ( { model
                | relatedVideos = Data.PeerTube.Failed "Échec de la récupération des vidéos"
                , notifications =
                    "Échec de la récupération des vidéos"
                        |> Notifications.addError model.notifications
              }
            , Cmd.none
            , Nothing
            )

        LoadMore ->
            let
                newCount =
                    model.numRelatedVideosToDisplay + numRelatedVideos

                loadMoreState =
                    case model.relatedVideos of
                        Data.PeerTube.Received relatedVideos ->
                            if newCount >= List.length relatedVideos then
                                Components.Disabled

                            else
                                Components.NotLoading

                        _ ->
                            Components.NotLoading
            in
            ( { model
                | numRelatedVideosToDisplay = model.numRelatedVideosToDisplay + numRelatedVideos
                , loadMoreState = loadMoreState
              }
            , Cmd.none
            , Nothing
            )

        ActivateTab tab ->
            ( { model | activeTab = tab }
            , Cmd.none
            , Nothing
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }
            , Cmd.none
            , Nothing
            )

        AskDeleteConfirmation ->
            ( { model | displayDeleteModal = True }
            , Cmd.none
            , Nothing
            )

        DiscardDeleteConfirmation ->
            ( { model | displayDeleteModal = False }
            , Cmd.none
            , Nothing
            )

        DeleteVideo video ->
            case session.userToken of
                Just userToken ->
                    ( { model | deletedVideo = Data.PeerTube.Requested }
                    , Request.PeerTube.deleteVideo
                        video
                        userToken
                        session.peerTubeURL
                        VideoDeleted
                    , Nothing
                    )

                Nothing ->
                    ( model, Cmd.none, Nothing )

        VideoDeleted (Ok _) ->
            ( { model
                | deletedVideo = Data.PeerTube.Received ()
                , notifications =
                    "Vidéo supprimée avec succès"
                        |> Notifications.addSuccess model.notifications
              }
            , Cmd.none
            , Nothing
            )

        VideoDeleted (Err _) ->
            ( { model
                | deletedVideo = Data.PeerTube.Failed "Échec de la suppression de la vidéo"
                , notifications =
                    "Échec de la suppression de la vidéo"
                        |> Notifications.addError model.notifications
              }
            , Cmd.none
            , Nothing
            )

        FavoriteStatusReceived (Ok authResult) ->
            let
                maybeFavoriteData =
                    Request.PeerTube.extractResult authResult

                favoriteStatus =
                    case maybeFavoriteData of
                        Just favoriteData ->
                            Favorite favoriteData

                        Nothing ->
                            NotFavorite
            in
            ( { model | favoriteStatus = favoriteStatus }
            , Cmd.none
            , Request.PeerTube.extractSessionMsg authResult
            )

        FavoriteStatusReceived (Err _) ->
            ( { model | favoriteStatus = Unknown }
            , Cmd.none
            , Nothing
            )

        RemoveFromFavorite favoriteData ->
            case session.userToken of
                Just userToken ->
                    ( { model | togglingFavoriteStatus = Data.PeerTube.Requested }
                    , Request.PeerTube.removeFromFavorite
                        favoriteData
                        userToken
                        session.peerTubeURL
                        RemovedFromFavoriteReceived
                    , Nothing
                    )

                _ ->
                    ( model, Cmd.none, Nothing )

        RemovedFromFavoriteReceived (Ok _) ->
            ( { model
                | togglingFavoriteStatus = Data.PeerTube.Received ()
                , favoriteStatus = NotFavorite
              }
            , Cmd.none
            , Nothing
            )

        RemovedFromFavoriteReceived (Err _) ->
            ( { model
                | togglingFavoriteStatus = Data.PeerTube.Failed "Échec du changement de statut de favori de la vidéo"
                , notifications =
                    "Échec de la suppression de la vidéo des favoris"
                        |> Notifications.addError model.notifications
              }
            , Cmd.none
            , Nothing
            )

        AddToFavorite ->
            case ( model.videoData, session.userToken, session.userInfo ) of
                ( Data.PeerTube.Received videoData, Just userToken, Just userInfo ) ->
                    ( { model | togglingFavoriteStatus = Data.PeerTube.Requested }
                    , Request.PeerTube.addToFavorite
                        videoData.id
                        userInfo.playlistID
                        userToken
                        session.peerTubeURL
                        AddedToFavoriteReceived
                    , Nothing
                    )

                _ ->
                    ( model, Cmd.none, Nothing )

        AddedToFavoriteReceived (Ok authResult) ->
            let
                favoriteData =
                    Request.PeerTube.extractResult authResult
            in
            ( { model
                | togglingFavoriteStatus = Data.PeerTube.Received ()
                , favoriteStatus = Favorite favoriteData
              }
            , Cmd.none
            , Nothing
            )

        AddedToFavoriteReceived (Err _) ->
            ( { model
                | togglingFavoriteStatus = Data.PeerTube.Failed "Échec du changement de statut de favori de la vidéo"
                , notifications =
                    "Échec de l'ajout de la vidéo aux favoris"
                        |> Notifications.addError model.notifications
              }
            , Cmd.none
            , Nothing
            )


dedupVideos : List Data.PeerTube.Video -> List Data.PeerTube.Video
dedupVideos videos =
    videos
        |> List.foldl
            (\video videoList ->
                if List.member video videoList then
                    videoList

                else
                    video :: videoList
            )
            []
        |> List.reverse


scrollToComment : Maybe String -> Model -> Cmd Msg
scrollToComment maybeCommentID model =
    if model.comments /= Data.PeerTube.Requested && model.videoData /= Data.PeerTube.Requested then
        -- Only scroll to the selected comment if we received both the video and the comments.
        case maybeCommentID of
            Just commentID ->
                Dom.getElement commentID
                    |> Task.andThen
                        (\comment ->
                            Dom.setViewport 0 comment.element.y
                        )
                    |> Task.attempt (\_ -> NoOp)

            Nothing ->
                Cmd.none

    else
        Cmd.none


view : Session -> Model -> Components.Document Msg
view { peerTubeURL, navigatorShare, url, userInfo } { videoID, title, videoTitle, videoData, comments, comment, commentData, refreshing, attachmentData, progress, notifications, attachmentList, relatedVideos, numRelatedVideosToDisplay, loadMoreState, activeTab, deletedVideo, displayDeleteModal, favoriteStatus, togglingFavoriteStatus } =
    let
        commentFormNode =
            H.div [ HA.class "video_contribution" ]
                [ case ( commentData, attachmentData ) of
                    ( Data.PeerTube.Failed _, _ ) ->
                        H.div []
                            [ H.text "Erreur lors de l'ajout de la contribution"
                            ]

                    ( _, Data.PeerTube.Failed _ ) ->
                        H.div []
                            [ H.text "Erreur lors de l'envoi de la pièce jointe"
                            ]

                    ( Data.PeerTube.Received _, Data.PeerTube.Received _ ) ->
                        H.div []
                            [ H.text "Merci pour votre contribution !"
                            ]

                    ( Data.PeerTube.Received _, Data.PeerTube.NotRequested ) ->
                        H.div []
                            [ H.text "Merci pour votre contribution !"
                            ]

                    _ ->
                        viewCommentForm comment userInfo refreshing commentData attachmentData progress
                ]

        displayTab tab tabTitle =
            H.a
                [ HA.href "#"
                , HA.class <|
                    if activeTab == tab then
                        "active"

                    else
                        ""
                , HE.onClick <| ActivateTab tab
                ]
                [ H.text tabTitle ]
    in
    { title = title
    , pageTitle = "Vidéo"
    , pageSubTitle = videoTitle
    , body =
        [ H.map NotificationMsg (Notifications.view notifications)
        , viewBreadCrumbs videoData
        , H.section []
            (case deletedVideo of
                Data.PeerTube.Received _ ->
                    [ H.h2 [] [ H.text "Vidéo supprimée" ]
                    , H.text "Vous pouvez "
                    , H.a [ Route.href Route.Home ] [ H.text "retourner à la liste de vidéos" ]
                    ]

                _ ->
                    [ viewVideo
                        peerTubeURL
                        url
                        navigatorShare
                        videoData
                        comments
                        attachmentList
                        userInfo
                        deletedVideo
                        displayDeleteModal
                        favoriteStatus
                        togglingFavoriteStatus
                    , H.div [ HA.class "cols_height-four mobile-tabs" ]
                        [ H.div [ HA.class "mobile-only tab-headers" ]
                            [ displayTab ContributionTab "Contributions"
                            , displayTab RelatedVideosTab "Suggestions"
                            ]
                        , H.div
                            [ HA.class <|
                                if activeTab == ContributionTab then
                                    "active"

                                else
                                    ""
                            ]
                            [ viewComments videoID comments attachmentList
                            ]
                        , H.div
                            [ HA.class <|
                                if activeTab == RelatedVideosTab then
                                    "active"

                                else
                                    ""
                            ]
                            [ viewRelatedVideos peerTubeURL relatedVideos numRelatedVideosToDisplay loadMoreState
                            ]
                        ]
                    , H.div []
                        [ commentFormNode
                        ]
                    ]
            )
        ]
    }


viewBreadCrumbs : Data.PeerTube.RemoteData Data.PeerTube.Video -> H.Html Msg
viewBreadCrumbs videoData =
    case videoData of
        Data.PeerTube.Received video ->
            let
                keywordCrumbs =
                    video.tags
                        |> List.concatMap
                            (\keyword ->
                                [ H.text " / "
                                , H.a [ Route.href (Route.VideoList <| Route.Search keyword) ] [ H.text keyword ]
                                ]
                            )
            in
            H.div [ HA.class "breadcrumbs" ]
                ([ H.a [ Route.href Route.Home ] [ H.text "Accueil" ]
                 ]
                    ++ keywordCrumbs
                    ++ [ H.text " / "
                       , H.text video.name
                       ]
                )

        _ ->
            H.text ""


viewVideo :
    String
    -> Url
    -> Bool
    -> Data.PeerTube.RemoteData Data.PeerTube.Video
    -> Data.PeerTube.RemoteData (List Data.PeerTube.Comment)
    -> List Attachment
    -> Maybe Data.PeerTube.UserInfo
    -> Data.PeerTube.RemoteData ()
    -> Bool
    -> FavoriteStatus
    -> Data.PeerTube.RemoteData ()
    -> H.Html Msg
viewVideo peerTubeURL url navigatorShare videoData commentsData attachmentList userInfo deletedVideo displayDeleteModal favoriteStatus togglingFavoriteStatus =
    case videoData of
        Data.PeerTube.Received video ->
            viewVideoDetails peerTubeURL url navigatorShare video commentsData attachmentList userInfo deletedVideo displayDeleteModal favoriteStatus togglingFavoriteStatus

        Data.PeerTube.Requested ->
            H.p [] [ H.text "Chargement de la vidéo en cours..." ]

        _ ->
            H.p [] [ H.text "Vidéo non trouvée" ]


viewVideoDetails :
    String
    -> Url
    -> Bool
    -> Data.PeerTube.Video
    -> Data.PeerTube.RemoteData (List Data.PeerTube.Comment)
    -> List Attachment
    -> Maybe Data.PeerTube.UserInfo
    -> Data.PeerTube.RemoteData ()
    -> Bool
    -> FavoriteStatus
    -> Data.PeerTube.RemoteData ()
    -> H.Html Msg
viewVideoDetails peerTubeURL url navigatorShare video commentsData attachmentList userInfo deletedVideo displayDeleteModal favoriteStatus togglingFavoriteStatus =
    let
        shareText =
            "Vidéo sur Classe à 12 : " ++ video.name

        shareUrl =
            Url.toString url

        navigatorShareButton =
            if navigatorShare then
                [ H.li []
                    [ H.a
                        [ HE.onClick <| ShareVideo shareText
                        , HA.href "#"
                        , HA.title "Partager la vidéo en utilisant une application"
                        ]
                        [ H.i [ HA.class "fas fa-share-alt fa-2x" ] [] ]
                    ]
                ]

            else
                []

        shareButtons =
            H.ul [ HA.class "social" ]
                ([ H.li []
                    [ H.a
                        [ HA.href "https://www.facebook.com/sharer/sharer.php"
                        , HA.title "Partager la vidéo par facebook"
                        ]
                        [ H.img [ HA.src "%PUBLIC_URL%/images/icons/32x32/facebook_32_purple.svg" ] [] ]
                    ]
                 , H.li []
                    [ H.a
                        [ HA.href <| "http://twitter.com/share?text=" ++ shareText
                        , HA.title "Partager la vidéo par twitter"
                        ]
                        [ H.img [ HA.src "%PUBLIC_URL%/images/icons/32x32/twitter_32_purple.svg" ] [] ]
                    ]
                 , H.li []
                    [ H.a
                        [ HA.href <| "whatsapp://send?text=" ++ shareText ++ " : " ++ shareUrl
                        , HA.property "data-action" (Encode.string "share/whatsapp/share")
                        , HA.title "Partager la vidéo par whatsapp"
                        ]
                        [ H.img [ HA.src "%PUBLIC_URL%/images/icons/32x32/whatsapp_32_purple.svg" ] [] ]
                    ]
                 , H.li []
                    [ H.a
                        [ HA.href <| "mailto:?body=" ++ shareText ++ "&subject=" ++ shareText
                        , HA.title "Partager la vidéo par email"
                        ]
                        [ H.img [ HA.src "%PUBLIC_URL%/images/icons/32x32/message_32_purple.svg" ] [] ]
                    ]
                 , H.li []
                    [ H.a
                        [ HA.href "https://www.tchap.gouv.fr/"
                        , HA.title "Partager la vidéo par Tchap"
                        ]
                        [ H.img [ HA.src "%PUBLIC_URL%/images/icons/32x32/tchap_32_purple.svg" ] [] ]
                    ]
                 ]
                    ++ navigatorShareButton
                )

        getAttachmentUploader : Data.PeerTube.RemoteData (List Data.PeerTube.Comment) -> Attachment -> Maybe Data.PeerTube.Account
        getAttachmentUploader commentsData_ attachment =
            case commentsData_ of
                Data.PeerTube.Received comments ->
                    comments
                        |> List.Extra.find (\comment -> String.fromInt comment.id == attachment.commentID)
                        |> Maybe.map .account

                _ ->
                    Nothing

        viewUploader : Data.PeerTube.Account -> H.Html Msg
        viewUploader uploader =
            H.div []
                [ H.text "Par "
                , H.a
                    [ Route.href <| Route.Profile uploader.name
                    , HA.class "comment_author"
                    ]
                    [ H.text uploader.displayName ]
                ]

        activeAttachmentList =
            attachmentList
                |> List.filter
                    (\attachment ->
                        case getAttachmentUploader commentsData attachment of
                            Just _ ->
                                True

                            _ ->
                                False
                    )

        viewAttachments =
            H.div [ HA.class "video_resources" ]
                [ H.h4 [] [ H.text "Ressources" ]
                , H.ul []
                    (activeAttachmentList
                        |> List.map
                            (\attachment ->
                                H.li []
                                    [ H.img
                                        [ HA.src "%PUBLIC_URL%/images/icons/32x32/support_32_purple.svg"
                                        , HA.title ""
                                        ]
                                        []
                                    , H.a
                                        [ HA.href <| "#" ++ attachment.commentID
                                        , HA.class "comment-link"
                                        , HE.onClick <| CommentSelected attachment.commentID
                                        ]
                                        [ H.text attachment.filename ]
                                    , H.span [ HA.class "file_info" ]
                                        [ attachment.contentInfo
                                            |> Maybe.map (\info -> info.mimeType ++ " - " ++ info.contentLength)
                                            |> Maybe.withDefault ""
                                            |> H.text
                                        ]
                                    , getAttachmentUploader commentsData attachment
                                        |> Maybe.map viewUploader
                                        |> Maybe.withDefault (H.text "")
                                    ]
                            )
                    )
                ]

        deleteVideoNode =
            case userInfo of
                Just info ->
                    let
                        buttonState =
                            case deletedVideo of
                                Data.PeerTube.Requested ->
                                    Components.Loading

                                _ ->
                                    Components.NotLoading
                    in
                    if info.username == video.account.name then
                        H.div [ HA.id "delete-video" ]
                            [ H.button
                                [ HE.onClick AskDeleteConfirmation
                                ]
                                [ H.img
                                    [ HA.src "%PUBLIC_URL%/images/icons/24x24/delete_24_purple.svg"
                                    ]
                                    []
                                , H.text "Supprimer cette vidéo"
                                ]
                            , H.div
                                [ HA.class "modal__backdrop"
                                , HA.class <|
                                    if displayDeleteModal then
                                        "active"

                                    else
                                        ""
                                ]
                                [ H.div [ HA.class "modal" ]
                                    [ H.h2 []
                                        [ H.text "Êtes-vous sûr de vouloir supprimer cette vidéo ? Cette action est irréversible."
                                        ]
                                    , Components.button "Oui je confirme, supprimer cette vidéo" buttonState (Just <| DeleteVideo video)
                                    , H.br [] []
                                    , H.a
                                        [ HA.href "#"
                                        , HE.onClick DiscardDeleteConfirmation
                                        ]
                                        [ H.text "Non, ne pas supprimer cette vidéo" ]
                                    ]
                                ]
                            ]

                    else
                        H.text ""

                Nothing ->
                    H.text ""

        favoriteVideoNode =
            let
                buttonState =
                    case togglingFavoriteStatus of
                        Data.PeerTube.Requested ->
                            Components.Loading

                        _ ->
                            Components.NotLoading
            in
            case favoriteStatus of
                Unknown ->
                    H.text ""

                Favorite favoriteData ->
                    Components.iconButton "Retirer des favoris" "%PUBLIC_URL%/images/icons/24x24/unfavorite_24_purple.svg" buttonState (Just <| RemoveFromFavorite favoriteData)

                NotFavorite ->
                    Components.iconButton "Ajouter aux favoris" "%PUBLIC_URL%/images/icons/24x24/heart_24_purple.svg" buttonState (Just <| AddToFavorite)
    in
    H.div
        []
        [ H.div [ HA.class "video_details" ]
            [ Page.Common.Video.title video
            , H.div []
                [ H.img
                    [ HA.src "%PUBLIC_URL%/images/icons/24x24/profil_24_purple.svg"
                    ]
                    []
                , Page.Common.Video.metadata video
                , Page.Common.Video.keywords video.tags
                ]
            ]
        , Page.Common.Video.playerForVideo video peerTubeURL
        , case video.files of
            Just files ->
                H.div [ HA.class "video_actions" ]
                    [ H.a
                        [ HA.href files.fileDownloadUrl ]
                        [ H.img
                            [ HA.src "%PUBLIC_URL%/images/icons/24x24/download_24_purple.svg"
                            ]
                            []
                        , H.text
                            "Télécharger cette vidéo"
                        ]
                    , deleteVideoNode
                    , favoriteVideoNode
                    ]

            Nothing ->
                H.text ""
        , H.div [ HA.class "video_infos cols_height-four" ]
            [ Page.Common.Video.description video
            , if activeAttachmentList /= [] then
                viewAttachments

              else
                H.text ""
            ]
        , H.div [ HA.class "video_share" ]
            [ H.text "Partager cette vidéo : "
            , shareButtons
            ]
        ]


viewComments :
    String
    -> Data.PeerTube.RemoteData (List Data.PeerTube.Comment)
    -> List Attachment
    -> H.Html Msg
viewComments videoID commentsData attachmentList =
    H.div [ HA.class "comment-list-wrapper" ]
        [ case commentsData of
            Data.PeerTube.Received comments ->
                H.div [ HA.class "comment_wrapper" ]
                    [ H.h2 [] [ H.text "Contributions" ]
                    , H.ul [ HA.class "comment_list" ]
                        (comments
                            |> List.map (viewCommentDetails videoID attachmentList)
                        )
                    ]

            Data.PeerTube.Requested ->
                H.p [] [ H.text "Chargement des contributions en cours..." ]

            _ ->
                H.p [] [ H.text "Aucune contribution pour le moment" ]
        ]


viewCommentDetails : String -> List Attachment -> Data.PeerTube.Comment -> H.Html Msg
viewCommentDetails videoID attachmentList comment =
    let
        commentID =
            String.fromInt comment.id

        attachmentNodes =
            attachmentList
                |> List.filter (\attachment -> attachment.videoID == videoID && attachment.commentID == commentID)
                |> List.map
                    (\attachment ->
                        H.li []
                            [ H.img
                                [ HA.src "%PUBLIC_URL%/images/icons/32x32/support_32_purple.svg"
                                , HA.title ""
                                ]
                                []
                            , H.a [ HA.href <| attachment.url ] [ H.text attachment.filename ]

                            -- TODO : we don't have the mimetype or the file size yet.
                            -- , H.span [ HA.class "file_info" ]
                            --     [ H.text " Type - n Ko"
                            --     ]
                            ]
                    )
    in
    H.li
        [ HA.class "comment"
        , HA.id <| String.fromInt comment.id
        ]
        [ H.div [ HA.class "comment_avatar" ]
            [ H.img [] []
            ]
        , H.div [ HA.class "comment_content" ]
            [ H.a
                [ Route.href <| Route.Profile comment.account.name
                , HA.class "comment_author"
                ]
                [ H.h3 []
                    [ H.text comment.account.displayName
                    ]
                ]
            , H.a
                [ HA.href <| "#" ++ commentID
                , HA.class "comment_link"
                , HE.onClick <| CommentSelected commentID
                ]
                [ H.time [] [ H.text <| Dates.formatStringDatetime comment.createdAt ]
                ]
            , Markdown.toHtml [ HA.class "comment_value" ] comment.text
            , H.ul [ HA.class "comment_attachment" ] attachmentNodes
            ]
        ]


viewCommentForm :
    String
    -> Maybe Data.PeerTube.UserInfo
    -> Bool
    -> Data.PeerTube.RemoteData Data.PeerTube.Comment
    -> Data.PeerTube.RemoteData String
    -> Page.Common.Progress.Progress
    -> H.Html Msg
viewCommentForm comment userInfo refreshing commentData attachmentData progress =
    if not <| Data.Session.isLoggedIn userInfo then
        H.div []
            [ H.h2 []
                [ H.text "Votre contribution"
                ]
            , H.p []
                [ H.text "Remercier l'auteur de la vidéo, proposer une amélioration, apporter un retour d'expérience..."
                ]
            , Components.viewConnectNow "Pour ajouter une contribution veuillez vous " "connecter"
            ]

    else
        let
            formComplete =
                comment /= ""

            buttonState =
                if formComplete then
                    case commentData of
                        Data.PeerTube.Requested ->
                            Components.Loading

                        _ ->
                            if refreshing then
                                Components.Loading

                            else
                                Components.NotLoading

                else
                    Components.Disabled

            submitButton =
                Components.submitButton "Ajouter cette contribution" buttonState
        in
        H.div []
            [ H.div
                [ HA.style "display"
                    (if commentData == Data.PeerTube.NotRequested then
                        "block"

                     else
                        "none"
                    )
                ]
                [ H.h2 []
                    [ H.text "Apporter une contribution" ]
                , H.p [] [ H.text "Remercier l'auteur de la vidéo, proposer une amélioration, apporter un retour d'expérience..." ]
                , H.form
                    [ HE.onSubmit AddComment, HA.class "cols_seven-five" ]
                    [ H.div [ HA.class "form__group" ]
                        [ H.label [ HA.for "comment" ]
                            [ H.text "Votre commentaire" ]
                        , H.textarea
                            [ HA.id "comment"
                            , HA.placeholder "Tapez ici votre commentaire"
                            , HA.value comment
                            , HE.onInput UpdateCommentForm
                            ]
                            []
                        ]
                    , H.div [ HA.class "form__group" ]
                        [ H.label [ HA.for "attachment" ]
                            [ H.text "Lier un fichier" ]
                        , H.input
                            [ HA.class "file-input"
                            , HA.type_ "file"
                            , HA.id "attachment"
                            , Components.onFileSelected AttachmentSelected
                            ]
                            []
                        , submitButton
                        ]
                    ]
                ]
            , H.div
                [ HA.style "display"
                    (if attachmentData == Data.PeerTube.Requested || commentData == Data.PeerTube.Requested then
                        "block"

                     else
                        "none"
                    )
                ]
                [ H.h1 [] [ H.text "Envoi du fichier en cours, veuillez patienter..." ]
                , H.p [] [ H.text progress.message ]
                , H.progress
                    [ HA.class "is-large"
                    , HA.value <| String.fromInt progress.percentage
                    , HA.max "100"
                    ]
                    [ H.text <| String.fromInt progress.percentage ++ "%" ]
                ]
            ]


viewRelatedVideos : String -> Data.PeerTube.RemoteData (List Data.PeerTube.Video) -> Int -> Components.ButtonState -> H.Html Msg
viewRelatedVideos peerTubeURL relatedVideos numRelatedVideosToDisplay loadMoreState =
    case relatedVideos of
        Data.PeerTube.Received videos ->
            if videos /= [] then
                H.div [ HA.class "video_suggestion" ]
                    [ H.h4 [] [ H.text "Suggestions" ]
                    , H.div []
                        (videos
                            |> List.take numRelatedVideosToDisplay
                            |> List.map (Page.Common.Video.viewVideo peerTubeURL)
                        )
                    , Components.button "Afficher plus de vidéos" loadMoreState (Just LoadMore)
                    ]

            else
                H.div [] []

        _ ->
            H.div [] []

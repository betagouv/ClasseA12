module Page.Video exposing (Model, Msg(..), init, update, view)

import Array
import Browser.Dom as Dom
import Data.PeerTube
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Markdown
import Page.Common.Components as Components
import Page.Common.Dates as Dates
import Page.Common.Notifications as Notifications
import Page.Common.Progress
import Page.Common.Video
import Page.Common.XHR
import Ports
import Request.Files
import Request.PeerTube
import Route
import Set
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
    , notifications : Notifications.Model
    }


type alias Attachment =
    { commentID : String
    , videoID : String
    , filename : String
    , url : String
    }


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
    | AttachmentListReceived (Result Http.Error (List String))
    | RelatedVideosReceived (List String) (Result Http.Error (List Data.PeerTube.Video))
    | NotificationMsg Notifications.Msg
    | NoOp


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
      , notifications = Notifications.init
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
                    (video.tags
                        :: (video.tags |> List.map List.singleton)
                    )
                        -- Make sure we don't have duplicated, eg for a video that has only one keyword.
                        |> Set.fromList
                        |> Set.toList

                relatedVideosCommands =
                    relatedVideosKeywordsToRequest
                        |> List.map
                            (\keywords ->
                                let
                                    params =
                                        Request.PeerTube.withKeywords keywords Request.PeerTube.emptyVideoListParams
                                in
                                Request.PeerTube.getVideoList params session.peerTubeURL (RelatedVideosReceived keywords)
                            )
            in
            ( { model
                | videoData = Data.PeerTube.Received video
                , relatedVideos = Data.PeerTube.Requested
              }
            , Cmd.batch
                ([ scrollToComment session.url.fragment model
                 ]
                    ++ relatedVideosCommands
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
            ( { model | attachmentSelected = True }
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
            let
                attachments =
                    attachmentList
                        |> List.map (attachmentFromString session.filesURL)
                        -- Remove the `Nothing`s and keep the `Just`s
                        |> List.filterMap identity
            in
            ( { model | attachmentList = attachments }
            , Cmd.none
            , Nothing
            )

        AttachmentListReceived (Err error) ->
            let
                updatedModel =
                    case error of
                        Http.BadStatus response ->
                            if response.status.code == 404 then
                                { model | attachmentList = [] }

                            else
                                { model
                                    | notifications =
                                        "Échec de la récupération des pièces jointes"
                                            |> Notifications.addError model.notifications
                                }

                        _ ->
                            { model
                                | notifications =
                                    "Échec de la récupération des pièces jointes"
                                        |> Notifications.addError model.notifications
                            }
            in
            ( updatedModel
            , Cmd.none
            , Nothing
            )

        RelatedVideosReceived keywords (Ok videos) ->
            let
                newVideos =
                    videos
                        |> List.filter (\video -> video.uuid /= model.videoID)

                relatedVideos =
                    case model.relatedVideos of
                        Data.PeerTube.Received previousVideoList ->
                            if List.length keywords > 1 then
                                -- More than one keyword? It must be results from the request with all the keywords
                                -- so display those results first (they have more keywords in common)
                                (newVideos ++ previousVideoList)
                                    |> dedupVideos
                                    |> Data.PeerTube.Received

                            else
                                (previousVideoList ++ newVideos)
                                    |> dedupVideos
                                    |> Data.PeerTube.Received

                        _ ->
                            Data.PeerTube.Received newVideos
            in
            ( { model | relatedVideos = relatedVideos }
            , Cmd.none
            , Nothing
            )

        RelatedVideosReceived _ (Err _) ->
            ( { model
                | relatedVideos = Data.PeerTube.Failed "Échec de la récupération des vidéos"
                , notifications =
                    "Échec de la récupération des vidéos"
                        |> Notifications.addError model.notifications
              }
            , Cmd.none
            , Nothing
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }
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


attachmentFromString : String -> String -> Maybe Attachment
attachmentFromString baseURL str =
    let
        splitted =
            String.split "/" str
                |> Array.fromList

        -- Get the element at the given index, and return an empty string otherwise.
        get : Int -> Array.Array String -> String
        get index array =
            Array.get index array
                |> Maybe.withDefault ""
    in
    if Array.length splitted == 4 then
        -- The file url starts with a "/", so the first element in `splitted` is an empty string
        Just
            { videoID = get 1 splitted
            , commentID = get 2 splitted
            , filename = get 3 splitted
            , url = baseURL ++ str
            }

    else
        Nothing


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
view { peerTubeURL, navigatorShare, url, userInfo } { videoID, title, videoTitle, videoData, comments, comment, commentData, refreshing, attachmentData, progress, notifications, attachmentList, relatedVideos } =
    { title = title
    , pageTitle = "Vidéo"
    , pageSubTitle = videoTitle
    , body =
        [ H.map NotificationMsg (Notifications.view notifications)
        , viewBreadCrumbs videoData
        , H.section []
            [ viewVideo peerTubeURL url navigatorShare videoData attachmentList
            , H.div []
                [ viewComments videoID comments attachmentList
                , case commentData of
                    Data.PeerTube.Failed _ ->
                        H.div []
                            [ H.text "Erreur lors de l'ajout de la contribution"
                            ]

                    _ ->
                        viewCommentForm comment userInfo refreshing commentData attachmentData progress
                ]
            , H.div []
                [ viewRelatedVideos peerTubeURL relatedVideos
                ]
            ]
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
                                , H.a [ Route.href (Route.Search <| Just keyword) ] [ H.text keyword ]
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


viewVideo : String -> Url -> Bool -> Data.PeerTube.RemoteData Data.PeerTube.Video -> List Attachment -> H.Html Msg
viewVideo peerTubeURL url navigatorShare videoData attachmentList =
    case videoData of
        Data.PeerTube.Received video ->
            viewVideoDetails peerTubeURL url navigatorShare video attachmentList

        Data.PeerTube.Requested ->
            H.p [] [ H.text "Chargement de la vidéo en cours..." ]

        _ ->
            H.p [] [ H.text "Vidéo non trouvée" ]


viewVideoDetails : String -> Url -> Bool -> Data.PeerTube.Video -> List Attachment -> H.Html Msg
viewVideoDetails peerTubeURL url navigatorShare video attachmentList =
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
                        [ HA.href <| "mailto:?body=" ++ shareText ++ "&subject=" ++ shareText
                        , HA.title "Partager la vidéo par email"
                        ]
                        [ H.i [ HA.class "fas fa-envelope fa-2x" ] [] ]
                    ]
                 , H.li []
                    [ H.a
                        [ HA.href <| "http://twitter.com/share?text=" ++ shareText
                        , HA.title "Partager la vidéo par twitter"
                        ]
                        [ H.i [ HA.class "fab fa-twitter fa-2x" ] [] ]
                    ]
                 , H.li []
                    [ H.a
                        [ HA.href <| "whatsapp://send?text=" ++ shareText ++ " : " ++ shareUrl
                        , HA.property "data-action" (Encode.string "share/whatsapp/share")
                        , HA.title "Partager la vidéo par whatsapp"
                        ]
                        [ H.i [ HA.class "fab fa-whatsapp fa-2x" ] [] ]
                    ]
                 , H.li []
                    [ H.a
                        [ HA.href "https://www.facebook.com/sharer/sharer.php"
                        , HA.title "Partager la vidéo par facebook"
                        ]
                        [ H.i [ HA.class "fab fa-facebook-f fa-2x" ] [] ]
                    ]
                 , H.li []
                    [ H.a
                        [ HA.href "fb-messenger://share/"
                        , HA.title "Partager la vidéo par facebook messenger"
                        ]
                        [ H.i [ HA.class "fab fa-facebook-messenger fa-2x" ] [] ]
                    ]
                 ]
                    ++ navigatorShareButton
                )

        viewAttachments =
            if attachmentList /= [] then
                H.div [ HA.class "video_resources" ]
                    [ H.h3 [] [ H.text "Ressources" ]
                    , H.ul [ HA.class "list-reset" ]
                        (attachmentList
                            |> List.map
                                (\attachment ->
                                    H.li []
                                        [ H.a
                                            [ HA.href <| "#" ++ attachment.commentID
                                            , HA.class "comment-link"
                                            , HE.onClick <| CommentSelected attachment.commentID
                                            ]
                                            [ H.text attachment.filename ]
                                        ]
                                )
                        )
                    ]

            else
                H.div [] []
    in
    H.div
        []
        [ Page.Common.Video.playerForVideo video peerTubeURL
        , H.div [ HA.class "video_details" ]
            [ Page.Common.Video.title video
            , H.div []
                [ Page.Common.Video.metadata video
                , Page.Common.Video.keywords video.tags
                ]
            ]
        , H.div [ HA.class "video_infos" ]
            [ Page.Common.Video.description video
            , viewAttachments
            ]

        -- , shareButtons
        ]


viewComments : String -> Data.PeerTube.RemoteData (List Data.PeerTube.Comment) -> List Attachment -> H.Html Msg
viewComments videoID commentsData attachmentList =
    H.div [ HA.class "comment-list-wrapper" ]
        [ case commentsData of
            Data.PeerTube.Received comments ->
                H.div [ HA.class "comment-wrapper" ]
                    [ H.h2 [] [ H.text "Contributions" ]
                    , H.ul [ HA.class "comment_list list-reset" ]
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
                        H.div []
                            [ H.text "Pièce jointe : "
                            , H.a [ HA.href <| attachment.url ] [ H.text attachment.filename ]
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
                , HA.class "comment-author"
                ]
                [ H.h3 []
                    [ H.text comment.account.displayName
                    ]
                ]
            , H.a
                [ HA.href <| "#" ++ commentID
                , HA.class "comment-link"
                , HE.onClick <| CommentSelected commentID
                ]
                [ H.time [] [ H.text <| Dates.formatStringDatetime comment.createdAt ]
                ]
            , Markdown.toHtml [] comment.text
            , H.div [] attachmentNodes
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
        Components.viewConnectNow "Pour ajouter une contribution veuillez vous " "connecter"

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
            [ H.form
                [ HE.onSubmit AddComment ]
                [ H.h3 [] [ H.text "Ajouter une contribution" ]
                , H.div [ HA.class "form__group" ]
                    [ H.label [ HA.for "comment" ]
                        [ H.text "Remercier l'auteur de la vidéo, proposer une amélioration, apporter un retour d'expérience..." ]
                    , H.textarea
                        [ HA.id "comment"
                        , HA.value comment
                        , HE.onInput UpdateCommentForm
                        ]
                        []
                    ]
                , H.div [ HA.class "form__group" ]
                    [ H.label [ HA.for "attachment" ]
                        [ H.text "Envoyer un fichier image, doc..." ]
                    , H.input
                        [ HA.class "file-input"
                        , HA.type_ "file"
                        , HA.id "attachment"
                        , Components.onFileSelected AttachmentSelected
                        ]
                        []
                    ]
                , submitButton
                ]
            , H.div
                [ HA.classList
                    [ ( "modal__backdrop", True )
                    , ( "is-active", attachmentData == Data.PeerTube.Requested )
                    ]
                ]
                [ H.div [ HA.class "modal" ]
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
            ]


viewRelatedVideos : String -> Data.PeerTube.RemoteData (List Data.PeerTube.Video) -> H.Html Msg
viewRelatedVideos peerTubeURL relatedVideos =
    case relatedVideos of
        Data.PeerTube.Received videos ->
            if videos /= [] then
                H.div []
                    [ H.h5 [] [ H.text "Ces vidéos pourraient vous intéresser" ]
                    , H.div [ HA.class "row" ]
                        (videos
                            |> List.map (Page.Common.Video.viewVideo peerTubeURL)
                        )
                    ]

            else
                H.div [] []

        _ ->
            H.div [] []

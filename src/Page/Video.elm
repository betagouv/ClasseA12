module Page.Video exposing (Model, Msg(..), init, update, view)

import Browser.Dom as Dom
import Data.Kinto
import Data.PeerTube
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Kinto
import Markdown
import Page.Common.Components as Components
import Page.Common.Dates as Dates
import Page.Common.Notifications as Notifications
import Page.Common.Progress
import Page.Common.Video
import Page.Common.XHR
import Ports
import Request.ClasseAFiles
import Request.Kinto
import Request.KintoProfile
import Request.KintoVideo
import Request.PeerTube
import Route
import Task
import Time
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
    , attachmentList : List String
    , notifications : Notifications.Model
    }


type Msg
    = VideoReceived (Result Http.Error Data.PeerTube.Video)
    | ShareVideo String
    | CommentsReceived (Result Http.Error (List Data.PeerTube.Comment))
    | UpdateCommentForm String
    | AddComment
    | CommentAdded String (Result Http.Error Data.PeerTube.Comment)
    | CommentSelected String
    | AttachmentSelected
    | AttachmentSent Decode.Value
    | ProgressUpdated Decode.Value
    | AttachmentListReceived (Result Http.Error (List String))
    | NotificationMsg Notifications.Msg
    | NoOp


init : String -> String -> Session -> ( Model, Cmd Msg )
init videoID videoTitle session =
    let
        title =
            "Vidéo : "
                ++ (videoTitle
                        |> Url.percentDecode
                        |> Maybe.withDefault videoTitle
                   )
    in
    ( { title = title
      , videoID = videoID
      , videoData = Data.PeerTube.Requested
      , videoTitle = videoTitle
      , comments = Data.PeerTube.Requested
      , comment = ""
      , commentData = Data.PeerTube.NotRequested
      , refreshing = False
      , attachmentData = Data.PeerTube.NotRequested
      , attachmentSelected = False
      , progress = Page.Common.Progress.empty
      , attachmentList = []
      , notifications = Notifications.init
      }
    , Cmd.batch
        [ Request.PeerTube.getVideo videoID session.peerTubeURL VideoReceived
        , Request.PeerTube.getVideoCommentList videoID session.peerTubeURL CommentsReceived
        , Request.ClasseAFiles.getVideoAttachmentList videoID session.filesURL AttachmentListReceived
        ]
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg, Maybe Data.Session.Msg )
update session msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none, Nothing )

        VideoReceived (Ok video) ->
            ( { model | videoData = Data.PeerTube.Received video }
            , scrollToComment session.url.fragment model
            , Nothing
            )

        VideoReceived (Err error) ->
            ( { model
                | videoData = Data.PeerTube.Failed "Échec de la récupération de la vidéo"
                , notifications =
                    "Échec de la récupération de la vidéo"
                        |> Notifications.addError model.notifications
              }
            , Cmd.none
            , Nothing
            )

        ShareVideo shareText ->
            ( model, Ports.navigatorShare shareText, Nothing )

        CommentsReceived (Ok comments) ->
            let
                contributorIDs =
                    comments
                        |> List.map (\comment -> comment.account.name)
            in
            ( { model | comments = Data.PeerTube.Received comments }
            , scrollToComment session.url.fragment model
            , Nothing
            )

        CommentsReceived (Err error) ->
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
                Just { access_token } ->
                    ( { model | commentData = Data.PeerTube.Requested }
                    , Request.PeerTube.submitComment
                        model.comment
                        model.videoID
                        access_token
                        session.peerTubeURL
                        (CommentAdded access_token)
                    , Nothing
                    )

                Nothing ->
                    -- Profile not created yet: we shouldn't be there.
                    ( model, Cmd.none, Nothing )

        CommentAdded access_token (Ok comment) ->
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
                , Nothing
                )

            else
                ( { model
                    | commentData = Data.PeerTube.Received comment
                    , refreshing = True
                  }
                  -- Refresh the list of comments
                , Cmd.batch
                    [ Request.PeerTube.getVideoCommentList model.videoID session.peerTubeURL CommentsReceived
                    , Request.ClasseAFiles.getVideoAttachmentList model.videoID session.filesURL AttachmentListReceived
                    ]
                , Nothing
                )

        CommentAdded _ (Err error) ->
            ( { model
                | commentData = Data.PeerTube.Failed "Échec de l'ajout du commentaire"
                , notifications =
                    "Échec de l'ajout du commentaire"
                        |> Notifications.addError model.notifications
              }
            , Cmd.none
            , Data.Session.logoutIf401 error
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
                        , Request.ClasseAFiles.getVideoAttachmentList model.videoID session.filesURL AttachmentListReceived
                        ]
                    , Nothing
                    )

                Ok (Page.Common.XHR.BadStatus status statusText) ->
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

                Err error ->
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
            ( { model
                | notifications =
                    "Échec de la récupération des pièces jointes"
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


view : Session -> Model -> ( String, List (H.Html Msg) )
view { peerTubeURL, navigatorShare, staticFiles, url, userInfo, filesURL } { videoID, title, videoData, comments, comment, commentData, refreshing, attachmentData, progress, notifications, attachmentList } =
    ( title
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src staticFiles.logo_ca12, HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "Vidéo" ]
                , viewTitle videoData
                ]
            ]
      , H.div [ HA.class "main" ]
            [ H.map NotificationMsg (Notifications.view notifications)
            , H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ viewVideo peerTubeURL url navigatorShare videoData
                    ]
                , H.div [ HA.class "container" ]
                    [ viewComments videoID comments attachmentList filesURL
                    , case commentData of
                        Data.PeerTube.Failed error ->
                            H.div []
                                [ H.text "Erreur lors de l'ajout de la contribution"
                                ]

                        _ ->
                            viewCommentForm comment userInfo refreshing commentData attachmentData progress
                    ]
                ]
            ]
      ]
    )


viewTitle : Data.PeerTube.RemoteData Data.PeerTube.Video -> H.Html Msg
viewTitle videoData =
    case videoData of
        Data.PeerTube.Received video ->
            H.p [] [ H.text video.name ]

        _ ->
            H.p [] []


viewVideo : String -> Url -> Bool -> Data.PeerTube.RemoteData Data.PeerTube.Video -> H.Html Msg
viewVideo peerTubeURL url navigatorShare videoData =
    case videoData of
        Data.PeerTube.Received video ->
            viewVideoDetails peerTubeURL url navigatorShare video

        Data.PeerTube.Requested ->
            H.p [] [ H.text "Chargement de la vidéo en cours..." ]

        _ ->
            H.p [] [ H.text "Vidéo non trouvée" ]


viewVideoDetails : String -> Url -> Bool -> Data.PeerTube.Video -> H.Html Msg
viewVideoDetails peerTubeURL url navigatorShare video =
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
    in
    H.div
        []
        [ H.embed
            [ HA.src (peerTubeURL ++ video.embedPath)
            , HA.width 1000
            , HA.height 800
            ]
            []
        , Page.Common.Video.details video
        , Page.Common.Video.keywords video.tags
        , shareButtons
        ]


viewComments : String -> Data.PeerTube.RemoteData (List Data.PeerTube.Comment) -> List String -> String -> H.Html Msg
viewComments videoID commentsData attachmentList filesURL =
    H.div [ HA.class "comment-list-wrapper" ]
        [ case commentsData of
            Data.PeerTube.Received comments ->
                H.div [ HA.class "comment-wrapper" ]
                    [ H.h3 [] [ H.text "Contributions" ]
                    , H.ul [ HA.class "comment-list" ]
                        (comments
                            |> List.map (viewCommentDetails videoID attachmentList filesURL)
                        )
                    ]

            Data.PeerTube.Requested ->
                H.p [] [ H.text "Chargement des contributions en cours..." ]

            _ ->
                H.p [] [ H.text "Aucune contribution pour le moment" ]
        ]


viewCommentDetails : String -> List String -> String -> Data.PeerTube.Comment -> H.Html Msg
viewCommentDetails videoID attachmentList filesURL comment =
    let
        commentID =
            String.fromInt comment.id

        filePath =
            "/"
                ++ videoID
                ++ "/"
                ++ commentID
                ++ "/"

        attachmentNodes =
            attachmentList
                |> List.filter (String.startsWith filePath)
                |> List.map
                    (\attachment ->
                        let
                            filename =
                                attachment
                                    |> String.replace filePath ""
                        in
                        H.div []
                            [ H.text "Pièce jointe : "
                            , H.a [ HA.href <| filesURL ++ attachment ] [ H.text filename ]
                            ]
                    )
    in
    H.li
        [ HA.class "comment panel"
        , HA.id <| String.fromInt comment.id
        ]
        [ H.a
            [ HA.href <| "#" ++ commentID
            , HA.class "comment-link"
            , HE.onClick <| CommentSelected commentID
            ]
            [ H.time [] [ H.text <| Dates.formatStringDatetime comment.createdAt ]
            ]
        , H.a
            [ Route.href <| Route.Profile comment.account.name
            , HA.class "comment-author"
            ]
            [ H.text comment.account.displayName ]
        , Markdown.toHtml [] comment.text
        , H.div [] attachmentNodes
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
    if not <| Data.Session.isPeerTubeLoggedIn userInfo then
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

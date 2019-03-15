module Page.Video exposing (Model, Msg(..), init, update, view)

import Browser.Dom as Dom
import Data.Kinto
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Kinto
import Markdown
import Page.Common.Components
import Page.Common.Dates
import Page.Common.Progress
import Page.Common.Video
import Ports
import Request.Kinto
import Request.KintoComment
import Request.KintoProfile
import Request.KintoVideo
import Route
import Task
import Time
import Url exposing (Url)


type alias Model =
    { videoID : String
    , video : Data.Kinto.KintoData Data.Kinto.Video
    , videoAuthor : Data.Kinto.ProfileData
    , title : String
    , comments : Data.Kinto.KintoData Data.Kinto.CommentList
    , contributors : Data.Kinto.KintoData Data.Kinto.ProfileList
    , commentForm : Data.Kinto.Comment
    , commentData : Data.Kinto.KintoData Data.Kinto.Comment
    , refreshing : Bool
    , attachmentData : Data.Kinto.KintoData Data.Kinto.Attachment
    , attachmentSelected : Bool
    , progress : Page.Common.Progress.Progress
    }


type Msg
    = VideoReceived (Result Kinto.Error Data.Kinto.Video)
    | VideoAuthorReceived (Result Kinto.Error Data.Kinto.Profile)
    | ShareVideo String
    | CommentsReceived (Result Kinto.Error Data.Kinto.CommentList)
    | ContributorsReceived (Result Kinto.Error Data.Kinto.ProfileList)
    | UpdateCommentForm Data.Kinto.Comment
    | AttachmentSelected
    | AddComment
    | CommentAdded (Result Kinto.Error Data.Kinto.Comment)
    | AttachmentSent String
    | ProgressUpdated Decode.Value
    | CommentSelected String
    | NoOp
    | VideoCanPlay


init : String -> String -> Session -> ( Model, Cmd Msg )
init videoID title session =
    ( { videoID = videoID
      , video = Data.Kinto.Requested
      , videoAuthor = Data.Kinto.NotRequested
      , title = title
      , comments = Data.Kinto.Requested
      , contributors = Data.Kinto.NotRequested
      , commentForm = Data.Kinto.emptyComment
      , commentData = Data.Kinto.NotRequested
      , refreshing = False
      , attachmentData = Data.Kinto.NotRequested
      , attachmentSelected = False
      , progress = Page.Common.Progress.empty
      }
    , Cmd.batch
        [ Request.KintoVideo.getVideo session.kintoURL videoID VideoReceived
        , Request.KintoComment.getVideoCommentList session.kintoURL videoID CommentsReceived
        ]
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        VideoReceived (Ok video) ->
            ( { model | video = Data.Kinto.Received video }
            , Cmd.batch
                [ Request.KintoProfile.getProfile session.kintoURL video.profile VideoAuthorReceived
                , scrollToComment session.url.fragment model
                ]
            )

        VideoReceived (Err error) ->
            ( { model | video = Data.Kinto.Failed error }, Cmd.none )

        VideoAuthorReceived (Ok profile) ->
            ( { model | videoAuthor = Data.Kinto.Received profile }, Cmd.none )

        VideoAuthorReceived (Err error) ->
            ( { model | videoAuthor = Data.Kinto.Failed error }, Cmd.none )

        ShareVideo shareText ->
            ( model, Ports.navigatorShare shareText )

        CommentsReceived (Ok comments) ->
            let
                contributorIDs =
                    comments.objects
                        |> List.map (\comment -> comment.profile)
            in
            ( { model | comments = Data.Kinto.Received comments }
            , Cmd.batch
                [ Request.KintoProfile.getProfileList session.kintoURL contributorIDs ContributorsReceived
                , scrollToComment session.url.fragment model
                ]
            )

        CommentsReceived (Err error) ->
            ( { model | comments = Data.Kinto.Failed error }, Cmd.none )

        ContributorsReceived (Ok contributors) ->
            ( { model
                | contributors = Data.Kinto.Received contributors

                -- If we were refreshing the comments and contributors data, it's now done.
                , refreshing = False
                , commentData = Data.Kinto.NotRequested
                , commentForm = Data.Kinto.emptyComment
              }
            , Cmd.none
            )

        ContributorsReceived (Err error) ->
            ( { model | contributors = Data.Kinto.Failed error }, Cmd.none )

        UpdateCommentForm commentForm ->
            ( { model | commentForm = commentForm }, Cmd.none )

        AttachmentSelected ->
            ( { model | attachmentSelected = True }, Cmd.none )

        AddComment ->
            case session.userData.profile of
                Just profile ->
                    let
                        commentForm =
                            model.commentForm

                        updatedCommentForm =
                            { commentForm | video = model.videoID, profile = profile }

                        client =
                            Request.Kinto.authClient session.kintoURL session.userData.username session.userData.password
                    in
                    ( { model
                        | commentForm = updatedCommentForm
                        , commentData = Data.Kinto.Requested
                      }
                    , Request.KintoComment.submitComment client updatedCommentForm CommentAdded
                    )

                Nothing ->
                    -- Profile not created yet: we shouldn't be there.
                    ( model, Cmd.none )

        CommentAdded (Ok comment) ->
            if model.attachmentSelected then
                let
                    submitAttachmentData : Ports.SubmitAttachmentData
                    submitAttachmentData =
                        { nodeID = "attachment"
                        , commentID = comment.id
                        , login = session.userData.username
                        , password = session.userData.password
                        }
                in
                ( { model
                    | commentData = Data.Kinto.Received comment
                    , attachmentData = Data.Kinto.Requested
                  }
                  -- Upload the attachment
                , Ports.submitAttachment submitAttachmentData
                )

            else
                ( { model
                    | commentData = Data.Kinto.Received comment
                    , refreshing = True
                  }
                  -- Refresh the list of comments (and then contributors)
                , Request.KintoComment.getVideoCommentList session.kintoURL model.videoID CommentsReceived
                )

        CommentAdded (Err error) ->
            ( { model | commentData = Data.Kinto.Failed error }, Cmd.none )

        ProgressUpdated value ->
            let
                progress =
                    Decode.decodeValue Page.Common.Progress.decoder value
                        |> Result.withDefault Page.Common.Progress.empty
            in
            ( { model | progress = progress }, Cmd.none )

        AttachmentSent response ->
            let
                result =
                    Decode.decodeString Data.Kinto.attachmentDecoder response
                        |> Result.mapError
                            (\_ ->
                                Decode.decodeString Kinto.errorDecoder response
                                    |> Result.map
                                        (\errorDetail ->
                                            Kinto.KintoError errorDetail.code errorDetail.message errorDetail
                                        )
                                    |> Result.withDefault (Kinto.NetworkError Http.NetworkError)
                            )

                kintoData =
                    case result of
                        Ok attachment ->
                            Data.Kinto.Received attachment

                        Err error ->
                            Data.Kinto.Failed error
            in
            ( { model
                | refreshing = True
                , commentForm = Data.Kinto.emptyComment
                , attachmentData = kintoData
                , attachmentSelected = False
                , progress = Page.Common.Progress.empty
              }
              -- Refresh the list of comments (and then contributors)
            , Request.KintoComment.getVideoCommentList session.kintoURL model.videoID CommentsReceived
            )

        CommentSelected commentID ->
            ( model, scrollToComment (Just commentID) model )

        VideoCanPlay ->
            ( model
            , scrollToComment session.url.fragment model
            )


scrollToComment : Maybe String -> Model -> Cmd Msg
scrollToComment maybeCommentID model =
    if model.comments /= Data.Kinto.Requested && model.video /= Data.Kinto.Requested then
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
view { timezone, navigatorShare, staticFiles, url, userData } { video, title, comments, contributors, commentForm, commentData, refreshing, attachmentData, progress, videoAuthor } =
    ( "Vidéo : "
        ++ (title
                |> Url.percentDecode
                |> Maybe.withDefault title
           )
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src staticFiles.logo_ca12, HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "Vidéo" ]
                , viewTitle video
                ]
            ]
      , H.div [ HA.class "main" ]
            [ H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ viewVideo timezone url navigatorShare video videoAuthor
                    ]
                , H.div [ HA.class "container" ]
                    [ viewComments timezone comments contributors
                    , case ( commentData, attachmentData ) of
                        ( Data.Kinto.Failed error, _ ) ->
                            H.div []
                                [ H.text "Erreur lors de l'ajout de la contribution : "
                                , H.text <| Kinto.errorToString error
                                ]

                        ( _, Data.Kinto.Failed error ) ->
                            H.div []
                                [ H.text "Erreur lors de l'ajout du fichier : "
                                , H.text <| Kinto.errorToString error
                                ]

                        _ ->
                            viewCommentForm commentForm userData refreshing commentData attachmentData progress
                    ]
                ]
            ]
      ]
    )


viewTitle : Data.Kinto.KintoData Data.Kinto.Video -> H.Html Msg
viewTitle videoData =
    case videoData of
        Data.Kinto.Received video ->
            H.p [] [ H.text video.title ]

        _ ->
            H.p [] []


viewVideo : Time.Zone -> Url -> Bool -> Data.Kinto.KintoData Data.Kinto.Video -> Data.Kinto.ProfileData -> H.Html Msg
viewVideo timezone url navigatorShare videoData profileData =
    case videoData of
        Data.Kinto.Received video ->
            viewVideoDetails timezone url navigatorShare video profileData

        Data.Kinto.Requested ->
            H.p [] [ H.text "Chargement de la vidéo en cours..." ]

        _ ->
            H.p [] [ H.text "Vidéo non trouvée" ]


viewVideoDetails : Time.Zone -> Url -> Bool -> Data.Kinto.Video -> Data.Kinto.ProfileData -> H.Html Msg
viewVideoDetails timezone url navigatorShare video profileData =
    let
        shareText =
            "Vidéo sur Classe à 12 : " ++ video.title

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
        [ Page.Common.Video.player VideoCanPlay video.attachment
        , Page.Common.Video.details timezone video profileData
        , Page.Common.Video.keywords video
        , shareButtons
        ]


viewComments :
    Time.Zone
    -> Data.Kinto.KintoData Data.Kinto.CommentList
    -> Data.Kinto.KintoData Data.Kinto.ProfileList
    -> H.Html Msg
viewComments timezone commentsData contributorsData =
    H.div [ HA.class "comment-list-wrapper" ]
        [ case commentsData of
            Data.Kinto.Received comments ->
                H.div [ HA.class "comment-wrapper" ]
                    [ H.h3 [] [ H.text "Contributions" ]
                    , H.ul [ HA.class "comment-list" ]
                        (comments.objects
                            |> List.map (viewCommentDetails timezone contributorsData)
                        )
                    ]

            Data.Kinto.Requested ->
                H.p [] [ H.text "Chargement des contributions en cours..." ]

            _ ->
                H.p [] [ H.text "Aucune contribution pour le moment" ]
        ]


viewCommentDetails : Time.Zone -> Data.Kinto.KintoData Data.Kinto.ProfileList -> Data.Kinto.Comment -> H.Html Msg
viewCommentDetails timezone contributorsData comment =
    let
        contributorName =
            case contributorsData of
                Data.Kinto.Received contributors ->
                    contributors.objects
                        |> List.filter (\contributor -> contributor.id == comment.profile)
                        |> List.head
                        |> Maybe.map (\contributor -> contributor.name)
                        -- If we didn't find any profile, display the profile ID.
                        |> Maybe.withDefault comment.profile

                _ ->
                    comment.profile

        attachment =
            if comment.attachment /= Data.Kinto.emptyAttachment then
                H.div []
                    [ H.text "Pièce jointe : "
                    , H.a [ HA.href comment.attachment.location ] [ H.text comment.attachment.filename ]
                    ]

            else
                H.div [] []
    in
    H.li
        [ HA.class "comment panel"
        , HA.id comment.id
        ]
        [ H.a
            [ HA.href <| "#" ++ comment.id
            , HA.class "comment-link"
            , HE.onClick <| CommentSelected comment.id
            ]
            [ H.time [] [ H.text <| Page.Common.Dates.posixToDate timezone comment.last_modified ]
            ]
        , H.a
            [ Route.href <| Route.Profile (Just comment.profile)
            , HA.class "comment-author"
            ]
            [ H.text contributorName ]
        , Markdown.toHtml [] comment.comment
        , attachment
        ]


viewCommentForm :
    Data.Kinto.Comment
    -> Data.Session.UserData
    -> Bool
    -> Data.Kinto.KintoData Data.Kinto.Comment
    -> Data.Kinto.KintoData Data.Kinto.Attachment
    -> Page.Common.Progress.Progress
    -> H.Html Msg
viewCommentForm commentForm userData refreshing commentData attachmentData progress =
    if not <| Data.Session.isLoggedIn userData then
        Page.Common.Components.viewConnectNow "Pour ajouter une contribution veuillez vous " "connecter"

    else
        let
            formComplete =
                commentForm.comment /= ""

            buttonState =
                if formComplete then
                    case commentData of
                        Data.Kinto.Requested ->
                            Page.Common.Components.Loading

                        Data.Kinto.Received _ ->
                            case attachmentData of
                                Data.Kinto.Requested ->
                                    Page.Common.Components.Loading

                                Data.Kinto.Received _ ->
                                    if refreshing then
                                        Page.Common.Components.Loading

                                    else
                                        Page.Common.Components.NotLoading

                                _ ->
                                    Page.Common.Components.NotLoading

                        _ ->
                            Page.Common.Components.NotLoading

                else
                    Page.Common.Components.Disabled

            submitButton =
                Page.Common.Components.submitButton "Ajouter cette contribution" buttonState
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
                        , HA.value commentForm.comment
                        , HE.onInput <| \comment -> UpdateCommentForm { commentForm | comment = comment }
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
                        , Page.Common.Components.onFileSelected AttachmentSelected
                        ]
                        []
                    ]
                , submitButton
                ]
            , H.div
                [ HA.classList
                    [ ( "modal__backdrop", True )
                    , ( "is-active", attachmentData == Data.Kinto.Requested )
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

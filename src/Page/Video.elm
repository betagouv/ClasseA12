module Page.Video exposing (Model, Msg(..), init, update, view)

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
import Page.Utils
import Ports
import Request.Kinto
import Request.KintoComment
import Request.KintoProfile
import Request.KintoVideo
import Route
import Time
import Url exposing (Url)


type alias Model =
    { videoID : String
    , video : Data.Kinto.KintoData Data.Kinto.Video
    , title : String
    , comments : Data.Kinto.KintoData Data.Kinto.CommentList
    , contributors : Data.Kinto.KintoData Data.Kinto.ProfileList
    , commentForm : Data.Kinto.Comment
    , commentData : Data.Kinto.KintoData Data.Kinto.Comment
    , refreshing : Bool
    , attachmentData : Data.Kinto.KintoData Data.Kinto.Attachment
    , attachmentSelected : Bool
    , progress : Page.Utils.Progress
    }


type Msg
    = VideoReceived (Result Kinto.Error Data.Kinto.Video)
    | ShareVideo String
    | CommentsReceived (Result Kinto.Error Data.Kinto.CommentList)
    | ContributorsReceived (Result Kinto.Error Data.Kinto.ProfileList)
    | UpdateCommentForm Data.Kinto.Comment
    | AttachmentSelected
    | AddComment
    | CommentAdded (Result Kinto.Error Data.Kinto.Comment)
    | AttachmentSent String
    | ProgressUpdated Decode.Value


init : String -> String -> Session -> ( Model, Cmd Msg )
init videoID title session =
    ( { videoID = videoID
      , video = Data.Kinto.Requested
      , title = title
      , comments = Data.Kinto.Requested
      , contributors = Data.Kinto.NotRequested
      , commentForm = Data.Kinto.emptyComment
      , commentData = Data.Kinto.NotRequested
      , refreshing = False
      , attachmentData = Data.Kinto.NotRequested
      , attachmentSelected = False
      , progress = Page.Utils.emptyProgress
      }
    , Cmd.batch
        [ Request.KintoVideo.getVideo session.kintoURL videoID VideoReceived
        , Request.KintoComment.getCommentList session.kintoURL videoID CommentsReceived
        ]
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        VideoReceived (Ok video) ->
            ( { model | video = Data.Kinto.Received video }, Cmd.none )

        VideoReceived (Err error) ->
            ( { model | video = Data.Kinto.Failed error }, Cmd.none )

        ShareVideo shareText ->
            ( model, Ports.navigatorShare shareText )

        CommentsReceived (Ok comments) ->
            let
                contributorIDs =
                    comments.objects
                        |> List.map (\comment -> comment.profile)
            in
            ( { model | comments = Data.Kinto.Received comments }
            , Request.KintoProfile.getProfileList session.kintoURL contributorIDs ContributorsReceived
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
                , Request.KintoComment.getCommentList session.kintoURL model.videoID CommentsReceived
                )

        CommentAdded (Err error) ->
            ( { model | commentData = Data.Kinto.Failed error }, Cmd.none )

        ProgressUpdated value ->
            let
                progress =
                    Decode.decodeValue Page.Utils.progressDecoder value
                        |> Result.withDefault Page.Utils.emptyProgress
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
                , progress = Page.Utils.emptyProgress
              }
              -- Refresh the list of comments (and then contributors)
            , Request.KintoComment.getCommentList session.kintoURL model.videoID CommentsReceived
            )


view : Session -> Model -> ( String, List (H.Html Msg) )
view { timezone, navigatorShare, url, userData } { video, title, comments, contributors, commentForm, commentData, refreshing, attachmentData, progress } =
    ( "Vidéo : "
        ++ (title
                |> Url.percentDecode
                |> Maybe.withDefault title
           )
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src "/logo_ca12.png", HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "Vidéo" ]
                , viewTitle video
                ]
            ]
      , H.div [ HA.class "main" ]
            [ H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ viewVideo timezone url navigatorShare video
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


viewVideo : Time.Zone -> Url -> Bool -> Data.Kinto.KintoData Data.Kinto.Video -> H.Html Msg
viewVideo timezone url navigatorShare videoData =
    case videoData of
        Data.Kinto.Received video ->
            viewVideoDetails timezone url navigatorShare video

        Data.Kinto.Requested ->
            H.p [] [ H.text "Chargement de la vidéo en cours..." ]

        _ ->
            H.p [] [ H.text "Vidéo non trouvée" ]


viewVideoDetails : Time.Zone -> Url -> Bool -> Data.Kinto.Video -> H.Html Msg
viewVideoDetails timezone url navigatorShare video =
    let
        keywordsNode =
            if video.keywords /= [] then
                [ H.div []
                    (video.keywords
                        |> List.map
                            (\keyword ->
                                H.div [ HA.class "label" ]
                                    [ H.text keyword ]
                            )
                    )
                ]

            else
                []

        detailsNodes =
            [ H.div []
                [ Page.Utils.viewVideoPlayer video.attachment
                , H.h3 [] [ H.text video.title ]
                , H.div []
                    [ H.time [] [ H.text <| Page.Utils.posixToDate timezone video.creation_date ] ]
                , Markdown.toHtml [] video.description
                ]
            ]

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

        shareNodes =
            [ H.ul [ HA.class "social" ]
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
            ]
    in
    H.div
        []
        (detailsNodes ++ keywordsNode ++ shareNodes)


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
    H.li [ HA.class "comment panel" ]
        [ H.time [] [ H.text <| Page.Utils.posixToDate timezone comment.last_modified ]
        , H.span [ HA.class "comment-author" ] [ H.text contributorName ]
        , Markdown.toHtml [] comment.comment
        , attachment
        ]


viewCommentForm :
    Data.Kinto.Comment
    -> Data.Session.UserData
    -> Bool
    -> Data.Kinto.KintoData Data.Kinto.Comment
    -> Data.Kinto.KintoData Data.Kinto.Attachment
    -> Page.Utils.Progress
    -> H.Html Msg
viewCommentForm commentForm userData refreshing commentData attachmentData progress =
    if not <| Data.Session.isLoggedIn userData then
        Page.Utils.viewConnectNow "Pour ajouter une contribution veuillez vous " "connecter"

    else
        let
            formComplete =
                commentForm.comment /= ""

            buttonState =
                if formComplete then
                    case commentData of
                        Data.Kinto.Requested ->
                            Page.Utils.Loading

                        Data.Kinto.Received _ ->
                            case attachmentData of
                                Data.Kinto.Requested ->
                                    Page.Utils.Loading

                                Data.Kinto.Received _ ->
                                    if refreshing then
                                        Page.Utils.Loading

                                    else
                                        Page.Utils.NotLoading

                                _ ->
                                    Page.Utils.NotLoading

                        _ ->
                            Page.Utils.NotLoading

                else
                    Page.Utils.Disabled

            submitButton =
                Page.Utils.submitButton "Ajouter cette contribution" buttonState
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
                        , Page.Utils.onFileSelected AttachmentSelected
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

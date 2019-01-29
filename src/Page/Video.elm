module Page.Video exposing (Model, Msg(..), init, update, view)

import Data.Kinto
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
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
    }


type Msg
    = VideoReceived (Result Kinto.Error Data.Kinto.Video)
    | ShareVideo String
    | CommentsReceived (Result Kinto.Error Data.Kinto.CommentList)
    | ContributorsReceived (Result Kinto.Error Data.Kinto.ProfileList)
    | UpdateCommentForm Data.Kinto.Comment
    | AddComment
    | CommentAdded (Result Kinto.Error Data.Kinto.Comment)


init : String -> String -> Session -> ( Model, Cmd Msg )
init videoID title session =
    ( { videoID = videoID
      , video = Data.Kinto.Requested
      , title = title
      , comments = Data.Kinto.Requested
      , contributors = Data.Kinto.NotRequested
      , commentForm = Data.Kinto.emptyComment
      , commentData = Data.Kinto.NotRequested
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
            ( { model | contributors = Data.Kinto.Received contributors }, Cmd.none )

        ContributorsReceived (Err error) ->
            ( { model | contributors = Data.Kinto.Failed error }, Cmd.none )

        UpdateCommentForm commentForm ->
            ( { model | commentForm = commentForm }, Cmd.none )

        AddComment ->
            let
                commentForm =
                    model.commentForm

                updatedCommentForm =
                    { commentForm | video = model.videoID, profile = session.userInfo.profile }

                client =
                    Request.Kinto.authClient session.kintoURL session.loginForm.username session.loginForm.password
            in
            ( { model | commentForm = updatedCommentForm }
            , Request.KintoComment.submitComment client updatedCommentForm CommentAdded
            )

        CommentAdded (Ok comment) ->
            ( { model | commentData = Data.Kinto.Received comment }, Cmd.none )

        CommentAdded (Err error) ->
            ( { model | commentData = Data.Kinto.Failed error }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view { timezone, navigatorShare, url, userInfo } { video, title, comments, contributors, commentForm, commentData } =
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
                    [ viewComments timezone comments contributors commentData
                    , case commentData of
                        Data.Kinto.Received comment ->
                            H.div [] [ H.text "Merci de votre contribution !" ]

                        Data.Kinto.Failed error ->
                            H.div []
                                [ H.text "Erreur lors de l'ajout de la contribution : "
                                , H.text <| Kinto.errorToString error
                                ]

                        _ ->
                            viewCommentForm commentForm userInfo commentData
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

        shareUrl = Url.toString url

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
    -> Data.Kinto.KintoData Data.Kinto.Comment
    -> H.Html Msg
viewComments timezone commentsData contributorsData commentData =
    let
        addedComment =
            case commentData of
                Data.Kinto.Received comment ->
                    -- If a new comment was just added, display it.
                    [ comment ]

                _ ->
                    []
    in
    H.div [ HA.class "comment-list-wrapper" ]
        [ case commentsData of
            Data.Kinto.Received comments ->
                H.div [ HA.class "comment-wrapper" ]
                    [ H.h3 [] [ H.text "Contributions" ]
                    , H.ul [ HA.class "comment-list" ]
                        ((comments.objects ++ addedComment)
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
    in
    H.li [ HA.class "comment panel" ]
        [ H.time [] [ H.text <| Page.Utils.posixToDate timezone comment.last_modified ]
        , H.span [ HA.class "comment-author" ] [ H.text contributorName ]
        , Markdown.toHtml [] comment.comment
        ]


viewCommentForm : Data.Kinto.Comment -> Data.Kinto.UserInfo -> Data.Kinto.KintoData Data.Kinto.Comment -> H.Html Msg
viewCommentForm commentForm userInfo commentData =
    if userInfo.profile == "" then
        -- No logged in user.
        H.div []
            [ H.p []
                [ H.text "Pour ajouter une contribution veuillez vous "
                , H.a [ Route.href Route.Login ] [ H.text "connecter" ]
                ]
            ]

    else
        let
            formComplete =
                commentForm.comment /= ""

            buttonState =
                if formComplete then
                    case commentData of
                        Data.Kinto.Requested ->
                            Page.Utils.Loading

                        _ ->
                            Page.Utils.NotLoading

                else
                    Page.Utils.Disabled

            submitButton =
                Page.Utils.submitButton "Ajouter cette contribution" buttonState
        in
        H.form
            [ HE.onSubmit AddComment ]
            [ H.h3 [] [ H.text "Ajouter une contribution" ]
            , H.div [ HA.class "form__group" ]
                [ H.label [ HA.for "comment" ]
                    [ H.text "Remercier l'auteur de la vidéo, proposer une amélioration, apporter un retour d'expérience..." ]
                , H.input
                    [ HA.type_ "text"
                    , HA.id "comment"
                    , HA.value commentForm.comment
                    , HE.onInput <| \comment -> UpdateCommentForm { commentForm | comment = comment }
                    ]
                    []
                ]
            , submitButton
            ]

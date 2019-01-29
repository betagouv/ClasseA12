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
import Request.KintoComment
import Request.KintoProfile
import Request.KintoVideo
import Time
import Url exposing (Url)


type alias Model =
    { videoID : String
    , video : Data.Kinto.KintoData Data.Kinto.Video
    , title : String
    , comments : Data.Kinto.KintoData Data.Kinto.CommentList
    , contributors : Data.Kinto.KintoData Data.Kinto.ProfileList
    }


type Msg
    = VideoReceived (Result Kinto.Error Data.Kinto.Video)
    | ShareVideo String
    | CommentsReceived (Result Kinto.Error Data.Kinto.CommentList)
    | ContributorsReceived (Result Kinto.Error Data.Kinto.ProfileList)


init : String -> String -> Session -> ( Model, Cmd Msg )
init videoID title session =
    ( { videoID = videoID
      , video = Data.Kinto.Requested
      , title = title
      , comments = Data.Kinto.Requested
      , contributors = Data.Kinto.NotRequested
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


view : Session -> Model -> ( String, List (H.Html Msg) )
view { timezone, navigatorShare, url } { video, title, comments, contributors } =
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


viewComments : Time.Zone -> Data.Kinto.KintoData Data.Kinto.CommentList -> Data.Kinto.KintoData Data.Kinto.ProfileList -> H.Html Msg
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
    in
    H.li [ HA.class "comment" ]
        [ H.div [ HA.class "comment-author" ] [ H.text contributorName ]
        , H.time [] [ H.text <| Page.Utils.posixToDate timezone comment.last_modified ]
        , Markdown.toHtml [] comment.comment
        ]

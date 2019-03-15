module Page.Comments exposing (Model, Msg(..), init, update, view)

import Data.Kinto
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Kinto
import Markdown
import Page.Common.Dates
import Page.Common.Notifications as Notifications
import Request.KintoBatch
import Request.KintoProfile
import Route
import Task
import Time


type alias Model =
    { commentDataList : Data.Kinto.KintoData (List Request.KintoBatch.CommentData)
    , notifications : Notifications.Model
    }


type Msg
    = NotificationMsg Notifications.Msg
    | CommentDataListReceived (Result Kinto.Error (List Request.KintoBatch.CommentData))


init : Session -> ( Model, Cmd Msg )
init session =
    ( { commentDataList = Data.Kinto.Requested
      , notifications = Notifications.init
      }
    , Task.attempt CommentDataListReceived <| Request.KintoBatch.getCommentDataListTask session.kintoURL
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        CommentDataListReceived (Ok commentDataList) ->
            ( { model | commentDataList = Data.Kinto.Received commentDataList }
            , Cmd.none
            )

        CommentDataListReceived (Err error) ->
            ( { model
                | notifications =
                    "Erreur lors de la récupération des commentaires : "
                        ++ Kinto.errorToString error
                        |> Notifications.addError model.notifications
                , commentDataList = Data.Kinto.NotRequested
              }
            , Cmd.none
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view session { notifications, commentDataList } =
    ( "Liste des commentaires"
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src session.staticFiles.logo_ca12, HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "List des commentaires" ]
                ]
            ]
      , H.div [ HA.class "main" ]
            [ H.map NotificationMsg (Notifications.view notifications)
            , H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ case commentDataList of
                        Data.Kinto.Received commentsData ->
                            viewComments session.timezone commentsData

                        _ ->
                            H.text "Récupération des commentaires..."
                    ]
                ]
            ]
      ]
    )


viewComments : Time.Zone -> List Request.KintoBatch.CommentData -> H.Html Msg
viewComments timezone comments =
    H.div [ HA.class "comment-list-wrapper" ]
        [ H.div [ HA.class "comment-wrapper" ]
            [ H.h3 [] [ H.text "Contributions" ]
            , H.ul [ HA.class "comment-list" ]
                (comments
                    |> List.map (viewCommentDetails timezone)
                )
            ]
        ]


viewCommentDetails : Time.Zone -> Request.KintoBatch.CommentData -> H.Html Msg
viewCommentDetails timezone { comment, contributor, video } =
    let
        contributorName =
            if contributor /= Data.Kinto.emptyProfile then
                contributor.name

            else
                comment.profile

        ( videoID, videoTitle ) =
            if video /= Data.Kinto.emptyVideo then
                ( video.id, video.title )

            else
                ( comment.video, "video-title" )

        attachment =
            if comment.attachment /= Data.Kinto.emptyAttachment then
                H.div []
                    [ H.text "Pièce jointe : "
                    , H.a [ HA.href comment.attachment.location ] [ H.text comment.attachment.filename ]
                    ]

            else
                H.div [] []

        commentURL =
            Route.Video videoID videoTitle
                |> Route.toString
                |> (\url -> url ++ ("#" ++ comment.id))
                |> HA.href
    in
    H.li
        [ HA.class "comment panel"
        , HA.id comment.id
        ]
        [ H.a
            [ commentURL
            , HA.class "comment-link"
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

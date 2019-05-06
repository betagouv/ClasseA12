module Page.Comments exposing (Model, Msg(..), init, update, view)

import Data.PeerTube
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Markdown
import Page.Common.Components
import Page.Common.Dates as Dates
import Page.Common.Notifications as Notifications
import Request.PeerTube
import Route


type alias Model =
    { title : String
    , commentDataList : Data.PeerTube.RemoteData (List Data.PeerTube.Comment)
    , notifications : Notifications.Model
    }


type Msg
    = NotificationMsg Notifications.Msg
    | CommentDataListReceived (Result Http.Error (List Data.PeerTube.Comment))


init : Session -> ( Model, Cmd Msg )
init session =
    ( { title = "Liste des commentaires"
      , commentDataList = Data.PeerTube.Requested
      , notifications = Notifications.init
      }
    , Request.PeerTube.getCommentList session.peerTubeURL CommentDataListReceived
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        CommentDataListReceived (Ok commentDataList) ->
            ( { model | commentDataList = Data.PeerTube.Received commentDataList }
            , Cmd.none
            )

        CommentDataListReceived (Err error) ->
            ( { model
                | notifications =
                    "Erreur lors de la récupération des commentaires"
                        |> Notifications.addError model.notifications
                , commentDataList = Data.PeerTube.NotRequested
              }
            , Cmd.none
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }, Cmd.none )


view : Session -> Model -> Page.Common.Components.Document Msg
view session { title, notifications, commentDataList } =
    { title = title
    , pageTitle = title
    , pageSubTitle = ""
    , body =
        [ H.map NotificationMsg (Notifications.view notifications)
        , H.div [ HA.class "section section-white" ]
            [ H.div [ HA.class "container" ]
                [ case commentDataList of
                    Data.PeerTube.Received commentsData ->
                        viewComments commentsData

                    _ ->
                        H.text "Récupération des commentaires..."
                ]
            ]
        ]
    }


viewComments : List Data.PeerTube.Comment -> H.Html Msg
viewComments comments =
    H.div [ HA.class "comment-list-wrapper" ]
        [ H.div [ HA.class "comment-wrapper" ]
            [ H.h3 [] [ H.text "Contributions" ]
            , H.ul [ HA.class "comment-list" ]
                (comments
                    |> List.map viewCommentDetails
                )
            ]
        ]


viewCommentDetails : Data.PeerTube.Comment -> H.Html Msg
viewCommentDetails comment =
    let
        commentURL =
            Route.Video (String.fromInt comment.videoId) "vidéo"
                |> Route.toString
                |> (\url -> url ++ ("#" ++ String.fromInt comment.id))
                |> HA.href
    in
    H.li
        [ HA.class "comment panel"
        , HA.id (String.fromInt comment.id)
        ]
        [ H.a
            [ commentURL
            , HA.class "comment-link"
            ]
            [ H.time [] [ H.text <| Dates.formatStringDatetime comment.createdAt ]
            ]
        , H.a
            [ Route.href <| Route.Profile comment.account.name
            , HA.class "comment-author"
            ]
            [ H.text comment.account.displayName ]
        , Markdown.toHtml [] comment.text
        ]

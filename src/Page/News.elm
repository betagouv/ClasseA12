module Page.News exposing (Model, Msg(..), init, update, view)

import Data.News
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Iso8601
import Markdown.Parser as Markdown
import Markdown.Renderer
import Page.Common.Components
import Page.Common.Dates as Dates
import RemoteData exposing (RemoteData(..), WebData)
import Request.News exposing (getPost)


type alias Model =
    { title : String
    , post : WebData Data.News.Post
    }


type Msg
    = PostReceived (WebData Data.News.Post)


init : String -> Session -> ( Model, Cmd Msg )
init postID _ =
    ( { title = "Échangeons nos pratiques pédagogiques en vidéo"
      , post = Loading
      }
    , getPost postID PostReceived
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        PostReceived data ->
            ( { model | post = data }, Cmd.none )


view : Session -> Model -> Page.Common.Components.Document Msg
view _ model =
    { title = model.title
    , pageTitle = "Toutes les actualités"
    , pageSubTitle = "Échangeons nos pratiques en toute simplicité !"
    , body =
        [ case model.post of
            Loading ->
                H.text "Chargement en cours..."

            Success post ->
                H.div []
                    [ H.section [ HA.id "post" ]
                        [ viewPost post ]
                    ]

            Failure _ ->
                H.text "Erreur lors du chargement de l'article"

            NotAsked ->
                H.text "Erreur"
        ]
    }


viewPost : Data.News.Post -> H.Html Msg
viewPost post =
    let
        createdAt =
            Iso8601.fromTime post.createdAt
                |> Dates.formatStringDatetime
    in
    H.article [ HA.class "news_item" ]
        [ H.div [ HA.class "title_wrapper" ]
            [ H.h1 [ HA.class "title" ]
                [ H.text post.title
                ]
            ]
        , H.img
            [ HA.src <| "/blog/" ++ post.id ++ "/" ++ post.image
            , HA.alt "Photo miniature"
            ]
            []
        , H.div []
            [ H.em []
                [ H.text <| "Par " ++ post.author ++ ", le " ++ createdAt ]
            , case
                post.content
                    |> Maybe.withDefault "Contenu introuvable"
                    |> Markdown.parse
                    |> Result.mapError deadEndsToString
                    |> Result.andThen (\ast -> Markdown.Renderer.render Markdown.Renderer.defaultHtmlRenderer ast)
              of
                Ok rendered ->
                    H.div [] rendered

                Err errors ->
                    H.text errors
            ]
        ]


deadEndsToString deadEnds =
    deadEnds
        |> List.map Markdown.deadEndToString
        |> String.join "\n"

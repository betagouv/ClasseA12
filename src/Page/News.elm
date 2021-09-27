module Page.News exposing (Model, Msg(..), init, update, view)

import Data.News
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA exposing (class)
import Iso8601
import Markdown.Parser as Markdown
import Markdown.Renderer
import Page.Common.Components
import Page.Common.Dates as Dates
import Ports
import RemoteData exposing (RemoteData(..), WebData)
import Request.News exposing (getPost)
import Url exposing (Url)


type alias Model =
    { title : String
    , post : WebData Data.News.Post
    }


type Msg
    = PostReceived (WebData Data.News.Post)
    | ShareNews String


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

        ShareNews shareText ->
            ( model, Ports.navigatorShare shareText )


view : Session -> Model -> Page.Common.Components.Document Msg
view { navigatorShare, url } model =
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
                        [ viewPost url navigatorShare post ]
                    ]

            Failure _ ->
                H.text "Erreur lors du chargement de l'article"

            NotAsked ->
                H.text "Erreur"
        ]
    }


viewPost : Url -> Bool -> Data.News.Post -> H.Html Msg
viewPost url navigatorShare post =
    let
        shareText =
            "Actualité sur Classe à 12 : " ++ post.title

        createdAt =
            Iso8601.fromTime post.createdAt
                |> Dates.formatStringDatetime
    in
    H.article [ HA.class "news-details" ]
        [ H.h1 []
            [ H.text post.title
            ]
        , H.div [ HA.class "news-details_meta" ]
            [ H.div []
                [ H.img [ HA.src "%PUBLIC_URL%/images/icons/24x24/profil_24_purple.svg", HA.alt "" ] []
                , H.text <| "Par " ++ post.author ++ ", le " ++ createdAt
                ]
            ]
        , H.p [ class "news-details_excerpt" ]
            [ H.text post.excerpt
            ]
        , H.img
            [ HA.src <| "/blog/" ++ post.id ++ "/" ++ post.image
            , HA.alt ""
            ]
            []
        , H.div [ HA.class "news-details_content" ]
            [ case
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
        , H.div []
            [ H.text "Partager cette actualité"
            , Page.Common.Components.shareButtons
                shareText
                (Url.toString url)
                navigatorShare
                (ShareNews shareText)
            ]
        ]


deadEndsToString deadEnds =
    deadEnds
        |> List.map Markdown.deadEndToString
        |> String.join "\n"

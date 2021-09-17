module Page.AllNews exposing (Model, Msg(..), init, update, view)

import Data.News
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Iso8601
import Page.Common.Components
import Page.Common.Dates as Dates
import RemoteData exposing (RemoteData(..), WebData)
import Request.News exposing (getPostList)
import Route


type alias Model =
    { title : String
    , postList : WebData (List Data.News.Post)
    }


type Msg
    = PostListReceived (WebData (List Data.News.Post))


init : Session -> ( Model, Cmd Msg )
init session =
    ( { title = "Échangeons nos pratiques pédagogiques en vidéo"
      , postList = Loading
      }
    , getPostList PostListReceived
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        PostListReceived data ->
            ( { model | postList = data }, Cmd.none )


view : Session -> Model -> Page.Common.Components.Document Msg
view _ model =
    { title = model.title
    , pageTitle = "Toutes les actualités"
    , pageSubTitle = "Échangeons nos pratiques en toute simplicité !"
    , body =
        [ case model.postList of
            Loading ->
                H.text "Chargement en cours..."

            Success postList ->
                H.div []
                    [ H.section [ HA.id "latest" ]
                        (H.div [ HA.class "title_wrapper" ]
                            [ H.h1 [ HA.class "title" ]
                                [ H.img [ HA.src "%PUBLIC_URL%/images/icons/48x48/alaune_48_bicolore.svg", HA.alt "" ] []
                                , H.text "Nouveautés"
                                ]
                            ]
                            :: (postList
                                    |> List.take 2
                                    |> List.map
                                        viewPost
                               )
                        )
                    , H.section [ HA.class "category", HA.id "archive" ]
                        (H.div [ HA.class "home-title_wrapper" ]
                            [ H.h2 [ HA.class "home-title" ]
                                [ H.text "Toutes les actualités"
                                ]
                            ]
                            :: (postList
                                    |> List.map
                                        viewPost
                               )
                        )
                    , H.a [ Route.href <| Route.VideoList Route.Latest ]
                        [ H.text "Charger toutes les actualités"
                        ]
                    ]

            Failure _ ->
                H.text "Erreur lors du chargement des actualités"

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
        [ H.div []
            [ H.div []
                [ H.h4 []
                    [ H.a [] [ H.text post.title ] ]
                , H.em []
                    [ H.text <| "Par " ++ post.author ++ ", le " ++ createdAt ]
                , H.p []
                    [ H.text post.excerpt ]
                ]
            ]
        , H.img [] []
        ]

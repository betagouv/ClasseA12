module Page.AllNews exposing (Model, Msg(..), init, update, view)

import Data.News
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Page.Common.Components
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
view _ { title } =
    { title = title
    , pageTitle = "Toutes les actualités"
    , pageSubTitle = "Échangeons nos pratiques en toute simplicité !"
    , body =
        [ H.section [ HA.id "latest" ]
            [ H.div [ HA.class "title_wrapper" ]
                [ H.h1 [ HA.class "title" ]
                    [ H.img [ HA.src "%PUBLIC_URL%/images/icons/48x48/alaune_48_bicolore.svg", HA.alt "" ] []
                    , H.text "Nouveautés"
                    ]
                ]
            , H.article [ HA.class "news_item" ]
                [ H.div []
                    [ H.div []
                        [ H.h4 []
                            [ H.a [] [ H.text "Classe à 12 : l'histoire d'un projet innovant" ] ]
                        , H.em []
                            [ H.text "Par l'équipe classe à 12, le 16 septembre 2021" ]
                        , H.p []
                            [ H.text "Classe à 12 est une communauté de professeurs qui partagent leurs pratiques professionnelles. Comment ? Grâce à des vidéos de moins de 2 minutes. Elles  sont réalisées et publiées librement. Il s’agit  d’une invitation à réfléchir collectivement à nos pratiques pédagogiques. À ce jour, ce sont près de 260 vidéos publiées et plus de 200 000 vues."
                            ]
                        ]
                    ]
                , H.img [] []
                ]
            ]
        , H.section [ HA.class "category", HA.id "archive" ]
            [ H.div [ HA.class "home-title_wrapper" ]
                [ H.h2 [ HA.class "home-title" ]
                    [ H.text "Toutes les actualités"
                    ]
                ]
            , H.article []
                [ H.img [] []
                , H.div []
                    [ H.div []
                        [ H.h4 []
                            [ H.a [] [ H.text "Classe à 12 : l'histoire d'un projet innovant" ] ]
                        , H.em []
                            [ H.text "Par l'équipe classe à 12, le 16 septembre 2021" ]
                        , H.p []
                            [ H.text "Classe à 12 est une communauté de professeurs qui partagent leurs pratiques professionnelles. Comment ? Grâce à des vidéos de moins de 2 minutes. Elles  sont réalisées et publiées librement. Il s’agit  d’une invitation à réfléchir collectivement à nos pratiques pédagogiques. À ce jour, ce sont près de 260 vidéos publiées et plus de 200 000 vues."
                            ]
                        ]
                    ]
                ]
            , H.a [ Route.href <| Route.VideoList Route.Latest ]
                [ H.text "Charger toutes les actualités"
                ]
            ]
        ]
    }

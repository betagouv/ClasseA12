module Page.AllNews exposing (Model, Msg(..), init, update, view, viewPost)

import Data.News
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Iso8601
import Page.Common.Components as Components
import Page.Common.Dates as Dates
import RemoteData exposing (RemoteData(..), WebData)
import Request.News exposing (getPostList)
import Route


type alias Model =
    { title : String
    , postList : WebData (List Data.News.Post)
    , numNewsToDisplay : Int
    }


type Msg
    = PostListReceived (WebData (List Data.News.Post))
    | DisplayMoreNews


numNewsToDisplay : Int
numNewsToDisplay =
    6


init : Session -> ( Model, Cmd Msg )
init session =
    ( { title = "Toutes les actualités"
      , postList = Loading
      , numNewsToDisplay = numNewsToDisplay
      }
    , getPostList PostListReceived
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        PostListReceived data ->
            ( { model | postList = data }, Cmd.none )

        DisplayMoreNews ->
            ( { model | numNewsToDisplay = model.numNewsToDisplay + numNewsToDisplay }
            , Cmd.none
            )


view : Session -> Model -> Components.Document Msg
view _ model =
    { title = model.title
    , pageTitle = "Toutes les actualités"
    , pageSubTitle = "Échangeons nos pratiques en toute simplicité !"
    , body =
        [ case model.postList of
            Loading ->
                H.text "Chargement en cours..."

            Success postList ->
                H.div [ HA.class "news" ]
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
                    , H.section [ HA.id "archive" ]
                        (H.div [ HA.class "title_wrapper" ]
                            [ H.h2 [ HA.class "title" ]
                                [ H.img [ HA.src "%PUBLIC_URL%/images/icons/48x48/news_48_bicolore.svg", HA.alt "" ] []
                                , H.text "Toutes les actualités"
                                ]
                            ]
                            :: (postList
                                    |> List.take model.numNewsToDisplay
                                    |> List.map
                                        viewPost
                               )
                        )
                    , H.div [ HA.class "center-wrapper" ]
                        [ viewLoadMoreNewsButton model.numNewsToDisplay postList ]
                    ]

            Failure _ ->
                H.text "Erreur lors du chargement des actualités"

            NotAsked ->
                H.text "Erreur"
        ]
    }


viewPost : Data.News.Post -> H.Html msg
viewPost post =
    let
        createdAt =
            Iso8601.fromTime post.createdAt
                |> Dates.formatStringDatetimeShort
    in
    H.article [ HA.class "news_item" ]
        [ H.div []
            [ H.div []
                [ H.h4 []
                    [ H.a [ Route.href <| Route.News post.id ] [ H.text post.title ] ]
                , H.span []
                    [ H.text <| "Par " ++ post.author ++ ", le " ++ createdAt ]
                , H.p []
                    [ H.text post.excerpt ]
                ]
            ]
        , H.img
            [ HA.src <| "/blog/" ++ post.id ++ "/image.png"
            , HA.alt ""
            ]
            []
        ]


viewLoadMoreNewsButton : Int -> List Data.News.Post -> H.Html Msg
viewLoadMoreNewsButton currentNumNewsToDisplay postList =
    let
        buttonState =
            if currentNumNewsToDisplay >= List.length postList then
                Components.Disabled

            else
                Components.NotLoading
    in
    Components.button "Charger plus d'actualités" buttonState (Just DisplayMoreNews)

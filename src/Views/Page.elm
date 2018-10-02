module Views.Page exposing (ActivePage(..), Config, frame)

import Browser exposing (Document)
import Data.Session exposing (Session)
import Html exposing (..)
import Html.Attributes exposing (alt, class, classList, href, src, title)
import Html.Events exposing (onClick)
import Route


type ActivePage
    = Home
    | Counter
    | Other


type alias Config msg =
    { session : Session
    , isMenuActive : Bool
    , toggleMenu : msg
    , activePage : ActivePage
    }


frame : Config msg -> ( String, List (Html.Html msg) ) -> Document msg
frame config ( title, content ) =
    { title = title ++ " | Classe à 12"
    , body =
        [ viewHeader config
        , div [ class "container" ]
            [ div [ class "section" ]
                content
            ]
        ]
    }


viewHeader : Config msg -> Html msg
viewHeader { activePage, isMenuActive, toggleMenu } =
    let
        linkMaybeActive page route caption =
            a
                [ Route.href route
                , classList
                    [ ( "navbar-item", True )
                    , ( "is-active", page == activePage )
                    ]
                ]
                [ text caption ]
    in
    nav [ class "navbar" ]
        [ div
            [ class "container" ]
            [ div [ class "navbar-brand" ]
                [ a
                    [ class "navbar-item"
                    , Route.href Route.Home
                    ]
                    [ img
                        [ src "./logo.jpg"
                        , alt "logo"
                        ]
                        []
                    , text "Classe à 12"
                    ]
                , span
                    [ classList
                        [ ( "navbar-burger burger", True )
                        , ( "is-active", isMenuActive )
                        ]
                    , onClick toggleMenu
                    ]
                    [ span [] []
                    , span [] []
                    , span [] []
                    ]
                ]
            , div
                [ classList
                    [ ( "navbar-menu", True )
                    , ( "is-active", isMenuActive )
                    ]
                ]
                [ div [ class "navbar-end" ]
                    [ linkMaybeActive Home Route.Home "Liste des vidéos"
                    , linkMaybeActive Counter Route.Counter "Second page"
                    , a
                        [ Html.Attributes.class "navbar-item"
                        , Html.Attributes.target "_blank"
                        , href "https://github.com/magopian/ClasseA12"
                        , title "Lien vers le code source sur Github"
                        ]
                        [ img
                            [ src "https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/Ei-sc-github.svg/768px-Ei-sc-github.svg.png"
                            , alt "Logo de Github"
                            ]
                            []
                        ]
                    ]
                ]
            ]
        ]

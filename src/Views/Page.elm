module Views.Page exposing (ActivePage(..), Config, frame)

import Browser exposing (Document)
import Data.Session exposing (Session)
import Html exposing (..)
import Html.Attributes exposing (alt, class, classList, href, src, title)
import Html.Events exposing (onClick)
import Route


type ActivePage
    = Home
    | About
    | Participate
    | Newsletter
    | NotFound


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
                    [ linkMaybeActive Home Route.Home "Nos vidéos"
                    , linkMaybeActive About Route.About "Classe à 12 ?"
                    , linkMaybeActive Participate Route.Participate "Je participe !"
                    , linkMaybeActive Newsletter Route.Newsletter "Inscrivez-vous à notre infolettre"
                    ]
                ]
            ]
        ]

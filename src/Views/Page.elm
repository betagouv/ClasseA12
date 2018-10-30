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


type alias Config =
    { session : Session
    , activePage : ActivePage
    }


frame : Config -> ( String, List (Html.Html msg) ) -> Document msg
frame config ( title, content ) =
    { title = title ++ " | Classe à 12"
    , body =
        [ viewHeader config ]
            ++ content
            ++ [ viewFooter ]
    }


viewHeader : Config -> Html msg
viewHeader { activePage } =
    let
        linkMaybeActive page route caption =
            li [ class "nav__item" ]
                [ a
                    [ Route.href route
                    , classList
                        [ ( "active", page == activePage )
                        ]
                    ]
                    [ text caption ]
                ]
    in
    header [ class "navbar" ]
        [ div
            [ class "navbar__container" ]
            [ a
                [ class "navbar__home"
                , Route.href Route.Home
                ]
                [ img
                    [ src "./logo.jpg"
                    , alt "logo"
                    , class "navbar__logo"
                    ]
                    []
                , text "classea12.beta.gouv.fr"
                ]
            , nav
                []
                [ ul [ class "nav__links" ]
                    [ linkMaybeActive Home Route.Home "Nos vidéos"
                    , linkMaybeActive About Route.About "Classe à 12 ?"
                    , linkMaybeActive Participate Route.Participate "Je participe !"
                    , linkMaybeActive Newsletter Route.Newsletter "Inscrivez-vous à notre infolettre"
                    ]
                ]
            ]
        ]


viewFooter : Html msg
viewFooter =
    footer [ class "footer" ]
        [ div [ class "container" ]
            [ div [ class "footer__logo" ]
                [ img
                    [ src "//res.cloudinary.com/hrscywv4p/image/upload/c_limit,fl_lossy,h_300,w_300,f_auto,q_auto/v1/1436014/r7mrgstb76x8onkugzno.jpg"
                    , alt "Logo du Lab 110bis"
                    ]
                    []
                , ul [ class "footer__social" ]
                    [ li []
                        [ a [ href "https://twitter.com/startupC12", class "icon icon-twitter" ]
                            [ i [ class "fa fa-twitter fa-2x" ] []
                            ]
                        ]
                    , li []
                        [ a [ href "https://github.com/betagouv/ClasseA12", class "icon icon-github" ]
                            [ i [ class "fa fa-github fa-2x" ] []
                            ]
                        ]
                    , li []
                        [ a [ href "mailto:contact@classea12.beta.gouv.fr?subject=Classes à 12 sur beta.gouv.fr", class "icon icon-mail" ]
                            [ i [ class "fa fa-envelope fa-2x" ] []
                            ]
                        ]
                    ]
                ]
            , ul [ class "footer__links" ]
                [ li []
                    [ h2 [] [ text "classea12.beta.gouv.fr" ] ]
                , li []
                    [ a [ href "#" ] [ text "Conditions générales d'utilisation" ] ]
                ]
            ]
        ]

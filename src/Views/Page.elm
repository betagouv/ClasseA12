module Views.Page exposing (ActivePage(..), Config, frame)

import Browser exposing (Document)
import Data.Session exposing (Session, isLoggedIn)
import Html exposing (..)
import Html.Attributes exposing (alt, class, classList, href, src, title)
import Html.Events exposing (onClick)
import Route


type ActivePage
    = Home
    | About
    | Participate
    | Newsletter
    | CGU
    | Convention
    | PrivacyPolicy
    | Admin
    | Video
    | Login
    | Register
    | ResetPassword
    | SetNewPassword
    | Activate
    | Profile
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
            ++ [ viewFooter config.session ]
    }


viewHeader : Config -> Html msg
viewHeader { activePage, session } =
    let
        loginIcon =
            a [ Route.href Route.Login, title "Se connecter" ]
                [ i [ class "fas fa-sign-in-alt" ] []
                , text " Se connecter"
                ]

        profileIcon =
            case session.userData.profile of
                Just profile ->
                    a [ Route.href <| Route.Profile (Just profile), title "Éditer son profil" ]
                        [ i [ class "far fa-user-circle" ] []
                        , text <| " " ++ session.userData.username
                        ]
                Nothing ->
                    a [ Route.href <| Route.Profile Nothing, title "Créer son profil" ]
                        [ i [ class "far fa-user-circle" ] []
                        , text <| " " ++ session.userData.username
                        ]

        loginProfileIcon =
            if isLoggedIn session.userData then
                profileIcon

            else
                loginIcon

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
                    [ src session.staticFiles.logo
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
                    , li [ class "nav__item" ]
                        [ a [ href "mailto:classea12@education.gouv.fr?subject=Classes à 12 sur beta.gouv.fr" ]
                            [ text "Contactez-nous" ]
                        ]
                    , linkMaybeActive Newsletter Route.Newsletter "Inscrivez-vous à notre infolettre"
                    , li [ class "nav__item" ] [ loginProfileIcon ]
                    ]
                ]
            ]
        ]


viewFooter : Session -> Html msg
viewFooter session =
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
                            [ i [ class "fab fa-twitter fa-2x" ] []
                            ]
                        ]
                    , li []
                        [ a [ href "https://github.com/betagouv/ClasseA12", class "icon icon-github" ]
                            [ i [ class "fab fa-github fa-2x" ] []
                            ]
                        ]
                    , li []
                        [ a [ href "mailto:classea12@education.gouv.fr?subject=Classes à 12 sur beta.gouv.fr", class "icon icon-mail" ]
                            [ i [ class "fas fa-envelope fa-2x" ] []
                            ]
                        ]
                    ]
                ]
            , ul [ class "footer__links" ]
                [ li []
                    [ h2 [] [ text "classea12.beta.gouv.fr" ] ]
                , li []
                    [ a [ Route.href Route.CGU ] [ text "Conditions générales d'utilisation" ] ]
                , li []
                    [ a [ Route.href Route.Convention ] [ text "Charte de bonne conduite" ] ]
                , li []
                    [ a [ Route.href Route.PrivacyPolicy ] [ text "Politique de confidentialité" ] ]
                , li []
                    [ text <| "Version : " ++ session.version ]
                ]
            ]
        ]

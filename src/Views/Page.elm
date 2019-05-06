module Views.Page exposing (ActivePage(..), Config, frame)

import Browser exposing (Document)
import Data.Kinto
import Data.Session exposing (Session, isPeerTubeLoggedIn)
import Html exposing (..)
import Html.Attributes exposing (alt, class, classList, href, placeholder, src, title, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Page.Common.Components
import Route


type ActivePage
    = Home
    | Search String
    | PeerTube
    | PeerTubeVideo
    | PeerTubeAccount
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
    | Comments
    | NotFound


type alias Config msg =
    { session : Session
    , updateSearchMsg : String -> msg
    , submitSearchMsg : msg
    , activePage : ActivePage
    }


frame : Config msg -> Page.Common.Components.Document msg -> Document msg
frame config { title, pageTitle, pageSubTitle, body } =
    { title = title ++ " | Classe à 12"
    , body =
        viewHeader config pageTitle pageSubTitle
            ++ viewContent config body
            ++ [ viewFooter config.session ]
    }


viewHeader : Config msg -> String -> String -> List (Html msg)
viewHeader { session, updateSearchMsg, submitSearchMsg } pageTitle pageSubTitle =
    let
        loginIcon =
            a [ Route.href Route.Login, title "Se connecter" ]
                [ i [ class "fas fa-sign-in-alt" ] []
                , text " Se connecter"
                ]

        profileIcon =
            case session.userInfo of
                Just userInfo ->
                    a [ Route.href <| Route.Profile userInfo.username, title "Éditer son profil" ]
                        [ i [ class "far fa-user-circle" ] []
                        , text <| " " ++ userInfo.username
                        ]

                Nothing ->
                    text ""

        loginProfileIcon =
            if isPeerTubeLoggedIn session.userInfo then
                profileIcon

            else
                loginIcon
    in
    [ header [ class "navbar" ]
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
                , text "classe-a-12.beta.gouv.fr"
                ]
            , nav
                []
                [ ul [ class "nav__links" ]
                    [ li [ class "nav__item" ]
                        [ form [ onSubmit submitSearchMsg ]
                            [ div [ class "search__group" ]
                                [ input
                                    [ type_ "search"
                                    , value session.search
                                    , onInput updateSearchMsg
                                    , placeholder "Exemple : Français"
                                    ]
                                    []
                                , button [ class "overlay-button" ]
                                    [ i [ class "fas fa-search" ] [] ]
                                ]
                            ]
                        ]
                    , li [ class "nav__item" ] [ loginProfileIcon ]
                    ]
                ]
            ]
        ]
    , div [ class "hero" ]
        [ div [ class "hero__banner" ] []
        , div [ class "hero__container" ]
            [ img
                [ src session.staticFiles.logo_ca12
                , class "hero__logo"
                ]
                []
            , h1 []
                [ text pageTitle ]
            , p []
                [ text pageSubTitle ]
            ]
        ]
    ]


viewContent : Config msg -> List (Html msg) -> List (Html msg)
viewContent { activePage } body =
    let
        linkMaybeActive page route caption =
            li []
                [ a
                    [ Route.href route
                    , classList
                        [ ( "active", page == activePage )
                        ]
                    ]
                    [ text caption ]
                ]
    in
    [ div [ class "dashboard" ]
        [ aside [ class "side-menu" ]
            [ ul []
                [ linkMaybeActive Home Route.Home "Accueil"
                , linkMaybeActive (Search "Nouveautés") (Route.Search Nothing) "Nouveautés"
                ]
            , h5 [] [ text "Catégories" ]
            , ul []
                (Data.Kinto.keywordList
                    |> List.map
                        (\( keyword, _ ) ->
                            let
                                route =
                                    Route.Search <| Just keyword
                            in
                            linkMaybeActive (Search keyword) route keyword
                        )
                )
            , h5 [] [ text "Le projet" ]
            , ul []
                [ linkMaybeActive About Route.About "Classe à 12 ?"
                , linkMaybeActive Participate Route.Participate "Je participe"
                , li [] [ a [ href "mailto:classea12@education.gouv.fr" ] [ text "Contactez-nous" ] ]

                -- Link to the Mailchimp signup form.
                , li [] [ a [ href "http://eepurl.com/gnJbYz" ] [ text "Inscrivez-vous à notre infolettre" ] ]
                ]
            ]
        , div [ class "main" ]
            body
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
                    [ h2 [] [ text "classe-a-12.beta.gouv.fr" ] ]
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

module Views.Page exposing (ActivePage(..), Config, frame)

import Browser exposing (Document)
import Data.PeerTube
import Data.Session exposing (Session, isLoggedIn)
import Html exposing (..)
import Html.Attributes exposing (alt, class, classList, href, placeholder, src, style, title, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Page.Common.Components
import Route
import String.Normalize


type ActivePage
    = Home
    | VideoList Route.VideoListQuery
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
    , openMenuMsg : msg
    , closeMenuMsg : msg
    , activePage : ActivePage
    }


frame : Config msg -> Page.Common.Components.Document msg -> Document msg
frame config { title, pageTitle, pageSubTitle, body } =
    { title = title ++ " | Devoirs Faits"
    , body =
        [ viewRFHeader
        , div [ class "main" ]
            [ div [ class "content" ]
                [ viewHeader config pageTitle pageSubTitle
                , viewContent body
                ]
            , viewAside config
            ]
        , viewFooter config.session
        ]
    }


viewRFHeader : Html msg
viewRFHeader =
    div [ class "rf-header" ]
        [ div [ class "rf-container" ]
            [ div [ class "rf-header__body" ]
                [ a []
                    [ img
                        [ class "rf-logo__image--custom"
                        , alt "Ministère de l'éducation nationale et de la jeunesse. - Retour à l'accueil"
                        , src "%PUBLIC_URL%/images/logos/marianne.svg"
                        ]
                        []
                    ]
                ]
            ]
        ]


viewHeader : Config msg -> String -> String -> Html msg
viewHeader ({ session, openMenuMsg, closeMenuMsg, activePage } as config) pageTitle pageSubTitle =
    let
        loginIcon =
            if session.isMenuOpened then
                -- This should never be the case on desktop, so display the mobile icon which is white
                a [ Route.href Route.Login, title "Se connecter" ]
                    [ img [ src "%PUBLIC_URL%/images/icons/32x32/connexion_32_white.svg" ] []
                    , text " Se connecter"
                    ]

            else
                a [ Route.href Route.Login, title "Se connecter" ]
                    [ img [ src "%PUBLIC_URL%/images/icons/32x32/connexion_32_purple.svg" ] []
                    , text " Se connecter"
                    ]

        icon =
            if session.isMenuOpened then
                -- This should never be the case on desktop, so display the mobile icon which is white
                "%PUBLIC_URL%/images/icons/32x32/profil_white.svg"

            else
                "%PUBLIC_URL%/images/icons/32x32/profil_purple.svg"

        profileIcon =
            case session.userInfo of
                Just userInfo ->
                    a [ Route.href <| Route.Profile userInfo.username, title "Éditer son profil" ]
                        [ img [ src icon ] []
                        , text <| " " ++ userInfo.username
                        ]

                Nothing ->
                    text ""

        loginProfileIcon =
            if isLoggedIn session.userInfo then
                profileIcon

            else
                loginIcon

        viewPublishVideoButton =
            case activePage of
                Participate ->
                    text ""

                _ ->
                    a [ class "btn", Route.href Route.Participate ]
                        [ text "Publier une vidéo" ]
    in
    header []
        [ p [ class "site-en-construction" ] [ text "Ce site est en construction" ]
        , div [ class "wrapper" ]
            [ searchForm config DesktopSearchForm
            , a [ href "/", class "mobile-only logo" ]
                [ img [ src "%PUBLIC_URL%/images/logos/devoirs-faits_mobile.svg", class "logo" ] []
                ]
            , div [ class "desktop-only" ]
                [ viewPublishVideoButton
                , loginProfileIcon
                ]
            , button
                [ class "mobile-only menu-opener"
                , onClick openMenuMsg
                ]
                [ text "Menu"
                , div []
                    [ span [] []
                    ]
                ]
            , aside
                [ class <|
                    "mobile-menu"
                        ++ (if session.isMenuOpened then
                                " opened"

                            else
                                ""
                           )
                ]
                ([ div []
                    [ viewPublishVideoButton
                    , button
                        [ class "close-mobile-menu"
                        , onClick closeMenuMsg
                        ]
                        [ img [ src "%PUBLIC_URL%/images/icons/24x24/close_24_purple.svg" ] []
                        ]
                    ]
                 , nav
                    []
                    [ loginProfileIcon
                    , searchForm config MobileSearchForm
                    ]
                 ]
                    ++ menuNodes config
                )
            ]
        ]


viewContent : List (Html msg) -> Html msg
viewContent body =
    main_ [ class "wrapper" ]
        body


viewFooter : Session -> Html msg
viewFooter session =
    footer [ class "rf-footer" ]
        [ div [ class "rf-container" ]
            [ div [ class "rf-footer__body" ]
                [ div [ class "rf-footer__brand" ]
                    [ a []
                        [ img
                            [ class "rf-logo__image--custom"
                            , alt "Ministère de l'éducation nationale et de la jeunesse. - Retour à l'accueil"
                            , src "%PUBLIC_URL%/images/logos/marianne.svg"
                            ]
                            []
                        ]
                    ]
                , div [ class "rf-footer__content" ]
                    [ ul [ class "rf-footer__content-links" ]
                        [ li [ class "rf-footer__content-item" ]
                            [ a [ class "rf-footer__content-link", href "https://legifrance.gouv.fr" ]
                                [ text "legifrance.gouv.fr" ]
                            ]
                        , li [ class "rf-footer__content-item" ]
                            [ a [ class "rf-footer__content-link", href "https://gouvernement.fr" ]
                                [ text "gouvernement.fr" ]
                            ]
                        , li [ class "rf-footer__content-item" ]
                            [ a [ class "rf-footer__content-link", href "https://service-public.fr" ]
                                [ text "service-public.fr" ]
                            ]
                        , li [ class "rf-footer__content-item" ]
                            [ a [ class "rf-footer__content-link", href "https://data.gouv.fr" ]
                                [ text "data.gouv.fr" ]
                            ]
                        ]
                    ]
                ]
            , div [ class "rf-footer__bottom" ]
                [ ul [ class "rf-footer__bottom-list" ]
                    [ li []
                        [ a [ class "rf-footer__bottom-link", Route.href Route.CGU ]
                            [ text "Conditions générales d'utilisation" ]
                        ]
                    , li []
                        [ a [ class "rf-footer__bottom-link", Route.href Route.Convention ]
                            [ text "Charte de bonne conduite" ]
                        ]
                    , li []
                        [ a [ class "rf-footer__bottom-link", Route.href Route.PrivacyPolicy ]
                            [ text "Politique de confidentialité" ]
                        ]
                    , li []
                        [ a [ class "rf-footer__bottom-link", href "#" ]
                            [ text "Accessibilité: non conforme" ]
                        ]
                    , li []
                        [ a [ class "rf-footer__bottom-link", Route.hrefWithAnchor Route.About "statistiques" ]
                            [ text "Nos statistiques" ]
                        ]
                    , li []
                        [ span [] [ text <| "Version : " ++ session.version ]
                        ]
                    ]
                , div [ class "rf-footer__bottom-copy" ]
                    [ text "Sauf mention contraire, tous les textes de ce site sont sous "
                    , a [ href "https://github.com/etalab/licence-ouverte/blob/master/LO.md" ]
                        [ text "licence etalab-2.0" ]
                    ]
                ]
            ]
        ]


viewAside : Config msg -> Html msg
viewAside config =
    aside [ class "side-menu desktop-only" ]
        ([ a [ href "/", class "logo" ]
            [ img [ src "%PUBLIC_URL%/images/logos/devoirs-faits.svg" ] []
            ]
         ]
            ++ menuNodes config
        )


menuNodes : Config msg -> List (Html msg)
menuNodes { activePage } =
    let
        linkMaybeActive page route caption =
            a
                [ Route.href route
                , classList
                    [ ( "active", page == activePage )
                    ]
                ]
                [ img [ src ("%PUBLIC_URL%/images/icons/32x32/" ++ String.Normalize.slug caption ++ "_32_white.svg") ] []
                , text caption
                ]
    in
    [ nav []
        [ linkMaybeActive Home Route.Home "Accueil"
        , linkMaybeActive (VideoList Route.Latest) (Route.VideoList Route.Latest) "Nouveautés"
        ]
    , div []
        [ h3 [] [ text "Catégories" ]
        , nav []
            (Data.PeerTube.keywordList
                |> List.map
                    (\keyword ->
                        let
                            route =
                                Route.VideoList <| Route.Keyword keyword
                        in
                        linkMaybeActive (VideoList <| Route.Search keyword) route keyword
                    )
            )
        , h3 [] [ text "Le projet" ]
        , nav []
            [ linkMaybeActive About Route.About "À propos"
            , linkMaybeActive Participate Route.Participate "Je participe"
            , a [ href "mailto:devoirsfaits.lesite@gmail.com" ]
                [ img [ src "%PUBLIC_URL%/images/icons/32x32/message_32_white.svg" ] []
                , text "Contactez-nous"
                ]

            -- Link to the Sendinblue signup form.
            , a [ href "https://2a48eb1e.sibforms.com/serve/MUIEAN1np-yvNRN4ZsQUXKVtIeWCxVKaPfQmSebruLFfs9KqjCB2RJJ7AJbGQYx0Np-Zs_ago8VuU7_zh1MFRwyOwNHa-w1ss9TS6WQBIm-KdakW03BShMk9lYlKIFCOz2JKMJ3sncij1STyCVT-FHUi8wPEb_eOaQuX62C3A-LkAH-pYVEtuURLk05OTQHOdTBz90wKFyDoTRpV" ]
                [ img [ src "%PUBLIC_URL%/images/icons/32x32/newsletter_32_white.svg" ] []
                , text "Inscrivez-vous à notre infolettre"
                ]
            ]
        , img
            [ class "label-devoirs-faits"
            , src "%PUBLIC_URL%/images/logos/label-devoirs-faits.svg"
            ]
            []
        , a
            [ class "rf-footer__brand-link"
            , href "https://www.education.gouv.fr/110-bis-le-lab-d-innovation-de-l-education-nationale-100157"
            , title "Retour à l'accueil"
            ]
            [ img [ alt "Logo 110bis - Lab de l'éducation nationale", src "%PUBLIC_URL%/images/logos/110bis.svg" ]
                []
            ]
        ]
    ]


type SearchForm
    = MobileSearchForm
    | DesktopSearchForm


searchForm : Config msg -> SearchForm -> Html.Html msg
searchForm { session, submitSearchMsg, updateSearchMsg } searchFormType =
    let
        searchInput =
            input
                [ type_ "search"
                , value session.search
                , onInput updateSearchMsg
                , placeholder "Exemple : Communication"
                ]
                []
    in
    case searchFormType of
        MobileSearchForm ->
            form [ onSubmit submitSearchMsg ]
                [ div [ class "search__group" ]
                    [ button [ class "search_button" ]
                        [ img [ src "%PUBLIC_URL%/images/icons/32x32/search_32_white.svg" ] [] ]
                    , searchInput
                    ]
                ]

        DesktopSearchForm ->
            form [ onSubmit submitSearchMsg, class "desktop-only" ]
                [ div [ class "search__group" ]
                    [ searchInput
                    , button [ class "search_button" ]
                        [ img [ src "%PUBLIC_URL%/images/icons/32x32/search_32_purple.svg" ] [] ]
                    ]
                ]

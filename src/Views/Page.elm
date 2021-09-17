module Views.Page exposing (ActivePage(..), Config, Frame(..), frame)

import Browser exposing (Document)
import Data.PeerTube
import Data.Session exposing (Session, isLoggedIn)
import Html exposing (..)
import Html.Attributes exposing (alt, class, classList, href, placeholder, src, title, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Page.Common.Components
import Route
import String.Normalize


type ActivePage
    = Home
    | AllVideos
    | VideoList Route.VideoListQuery
    | AllNews
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


type Frame
    = HomeFrame
    | VideoFrame
    | AboutFrame
    | NewsFrame


frameToString : Frame -> String
frameToString frameVariant =
    case frameVariant of
        HomeFrame ->
            "home"

        VideoFrame ->
            "video"

        AboutFrame ->
            "about"

        NewsFrame ->
            "news"


type alias Config msg =
    { session : Session
    , updateSearchMsg : String -> msg
    , submitSearchMsg : msg
    , openMenuMsg : msg
    , closeMenuMsg : msg
    , activePage : ActivePage
    }


frame : Frame -> Config msg -> Page.Common.Components.Document msg -> Document msg
frame frameVariant config { title, pageTitle, pageSubTitle, body } =
    { title = title ++ " | Classe à 12"
    , body =
        [ viewRFHeader frameVariant config pageTitle pageSubTitle
        , Html.main_
            [ class "main"
            , class <| frameToString frameVariant
            ]
            [ div [ class "content" ]
                [ viewHeader config pageTitle pageSubTitle
                , viewContent body
                ]
            , case frameVariant of
                HomeFrame ->
                    viewHomeAside config

                VideoFrame ->
                    viewVideoAside config

                AboutFrame ->
                    viewAboutAside config

                NewsFrame ->
                    viewNewsAside config
            ]
        , viewFooter config.session
        ]
    }


viewRFHeader : Frame -> Config msg -> String -> String -> Html msg
viewRFHeader activeFrame ({ session, openMenuMsg, closeMenuMsg, activePage } as config) pageTitle pageSubTitle =
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

        navLink : Frame -> Route.Route -> String -> Html msg
        navLink frameVariant route caption =
            a
                [ Route.href route
                , classList
                    [ ( "active", frameVariant == activeFrame )
                    ]
                ]
                [ text caption
                ]
    in
    header [ class "rf-header" ]
        [ div [ class "rf-container" ]
            [ div [ class "rf-header__body" ]
                [ img
                    [ class "rf-logo__image--custom"
                    , alt "Ministère de l'éducation nationale et de la jeunesse"
                    , src "%PUBLIC_URL%/images/logos/marianne.svg"
                    ]
                    []
                , a
                    [ href "/", class "rf-header__logo" ]
                    [ img [ src "%PUBLIC_URL%/images/logos/classea12-dark.svg" ] []
                    ]
                , nav [ class "rf-header__nav" ]
                    [ ul []
                        [ li []
                            [ navLink VideoFrame Route.AllVideos "Les vidéos" ]
                        , li []
                            [ navLink NewsFrame Route.AllNews "Actualités" ]
                        , li [] [ navLink AboutFrame Route.About "À propos" ]
                        , li []
                            [ a [ href "mailto:nicolas.leyri@beta.gouv.fr" ]
                                [ text "Contact" ]
                            ]
                        ]
                    ]
                , searchForm config DesktopSearchForm
                , div [ class "rf-header__actions" ]
                    [ viewPublishVideoButton
                    , loginProfileIcon
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
        [ div [ class "wrapper" ]
            [ a [ href "/", class "mobile-only logo" ]
                [ img [ src "%PUBLIC_URL%/images/logos/classea12.svg", class "logo" ] []
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
    div []
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


viewHomeAside : Config msg -> Html msg
viewHomeAside _ =
    aside [] []


viewVideoAside : Config msg -> Html msg
viewVideoAside config =
    aside [ class "side-menu" ]
        (menuNodes config)


viewAboutAside : Config msg -> Html msg
viewAboutAside { activePage } =
    let
        linkMaybeActive =
            linkMaybeActiveAside activePage
    in
    aside [ class "side-menu" ]
        [ nav []
            [ linkMaybeActive About Route.About "À propos de Classe à 12"
            , linkMaybeActive Participate Route.Participate "Participer"
            , linkMaybeActive Register Route.Register "S'inscrire"
            , a [ href "" ]
                [ img [ src "%PUBLIC_URL%/images/icons/32x32/faq-flash_32_purple.svg" ] []
                , text "Comment participer"
                ]
            , a [ href "mailto:nicolas.leyri@beta.gouv.fr" ]
                [ img [ src "%PUBLIC_URL%/images/icons/32x32/message_32_purple.svg" ] []
                , text "Nous contacter"
                ]
            , a [ href "https://599e9709.sibforms.com/serve/MUIEABa2ApUVsn_hLq_zTj7WPa6DOXQy18ZVPS0ojLpoE5crRUomeg6utwxbzb50w1_LFdzSalHWDlgbn9KB3AM-OhTSc3ytk5kuXT351AetkMjU4Vftiwe9SQ9u9LHi6ufQYU8mX3SV0S6UpnpIPhT3tc_mP36xJg5iZMpEv5LSoAdIz9K7DaXIWwPBMTIPxEASc0NvloWQNtQA" ]
                [ img [ src "%PUBLIC_URL%/images/icons/32x32/newsletter_32_purple.svg" ] []
                , text "Newsletter"
                ]
            , a [ href "" ]
                [ img [ src "%PUBLIC_URL%/images/icons/32x32/facebook_32_purple.svg" ] []
                , text "Facebook"
                ]
            , a [ href "" ]
                [ img [ src "%PUBLIC_URL%/images/icons/32x32/twitter_32_purple.svg" ] []
                , text "Twitter"
                ]
            ]
        ]


viewNewsAside : Config msg -> Html msg
viewNewsAside { activePage } =
    let
        linkMaybeActive =
            linkMaybeActiveAside activePage
    in
    aside [ class "side-menu" ]
        [ nav []
            [ linkMaybeActive AllNews Route.AllNews "Nouveautés"
            , a [ href "" ]
                [ img [ src "%PUBLIC_URL%/images/icons/32x32/nos-evenements_32_purple.svg" ] []
                , text "Nos événements"
                ]
            , a [ href "" ]
                [ img [ src "%PUBLIC_URL%/images/icons/32x32/les-challenges_32_purple.svg" ] []
                , text "Les challenges"
                ]
            , linkMaybeActive About Route.About "À propos de Classe à 12"
            ]
        ]


linkMaybeActiveAside : ActivePage -> ActivePage -> Route.Route -> String -> Html msg
linkMaybeActiveAside activePage page route caption =
    a
        [ Route.href route
        , classList
            [ ( "active", page == activePage )
            ]
        ]
        [ img [ src ("%PUBLIC_URL%/images/icons/32x32/" ++ String.Normalize.slug caption ++ "_32_purple.svg") ] []
        , text caption
        ]


menuNodes : Config msg -> List (Html msg)
menuNodes { activePage } =
    let
        linkMaybeActive =
            linkMaybeActiveAside activePage
    in
    [ nav [ class "desktop-only" ]
        [ ul []
            [ li [] [ linkMaybeActive AllVideos Route.AllVideos "Accueil videos" ]
            , li [] [ linkMaybeActive (VideoList Route.Latest) (Route.VideoList Route.Latest) "Nouveautés" ]
            , li [] [ linkMaybeActive (VideoList Route.Playlist) (Route.VideoList Route.Playlist) "La playlist de la semaine" ]
            , li [] [ linkMaybeActive (VideoList Route.FAQFlash) (Route.VideoList Route.FAQFlash) "FAQ Flash" ]
            ]
        , h3 [] [ text "Catégories" ]
        , ul []
            (Data.PeerTube.keywordList
                |> List.map
                    (\keyword ->
                        let
                            route =
                                Route.VideoList <| Route.Keyword keyword
                        in
                        li [] [ linkMaybeActive (VideoList <| Route.Keyword keyword) route keyword ]
                    )
            )
        ]
    , div [ class "desktop-only" ]
        [ a []
            [ img [ alt "Égalité des chances - L'école de la confiance - Dédoublement des classes", src "%PUBLIC_URL%/images/logos/ecoleconfiance.png" ]
                []
            ]
        , a
            [ href "https://www.education.gouv.fr/110-bis-le-lab-d-innovation-de-l-education-nationale-100157"
            ]
            [ img [ alt "Logo 110bis - Lab de l'éducation nationale", src "%PUBLIC_URL%/images/logos/110bis.svg" ]
                []
            ]
        ]
    , details [ class "mobile-only mobile-categories" ]
        [ summary [ class "" ]
            [ text "Choisir une catégorie"
            ]
        , nav []
            [ ul []
                [ li [] [ linkMaybeActive AllVideos Route.AllVideos "Accueil videos" ]
                , li [] [ linkMaybeActive (VideoList Route.Latest) (Route.VideoList Route.Latest) "Nouveautés" ]
                , li [] [ linkMaybeActive (VideoList Route.Playlist) (Route.VideoList Route.Playlist) "La playlist de la semaine" ]
                , li [] [ linkMaybeActive (VideoList Route.FAQFlash) (Route.VideoList Route.FAQFlash) "FAQ Flash" ]
                ]
            , h3 [] [ text "Catégories" ]
            , ul []
                (Data.PeerTube.keywordList
                    |> List.map
                        (\keyword ->
                            let
                                route =
                                    Route.VideoList <| Route.Keyword keyword
                            in
                            li [] [ linkMaybeActive (VideoList <| Route.Keyword keyword) route keyword ]
                        )
                )
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
                , placeholder "Exemple : Français"
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

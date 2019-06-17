module Views.Page exposing (ActivePage(..), Config, frame)

import Browser exposing (Document)
import Data.PeerTube
import Data.Session exposing (Session, isLoggedIn)
import Html exposing (..)
import Html.Attributes exposing (alt, class, classList, href, placeholder, src, style, title, type_, value)
import Html.Events exposing (onInput, onSubmit)
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
    , activePage : ActivePage
    }


frame : Config msg -> Page.Common.Components.Document msg -> Document msg
frame config { title, pageTitle, pageSubTitle, body } =
    { title = title ++ " | Classe à 12"
    , body =
        [ div [ class "content" ]
            [ viewHeader config pageTitle pageSubTitle
            , viewContent body
            , viewFooter config.session
            ]
        , viewAside config
        ]
    }


viewHeader : Config msg -> String -> String -> Html msg
viewHeader { session, updateSearchMsg, submitSearchMsg, activePage } pageTitle pageSubTitle =
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
    header []
        [ div [ class "wrapper" ]
            [ img [ alt "Ministère de l'éducation nationale et de la jeunesse", src "%PUBLIC_URL%/images/logos/marianne.svg" ]
                []

            -- TODO: unhide this when we have the functionality
            , nav [ style "visibility" "hidden", class "desktop-only" ]
                [ a [ href "" ]
                    [ text "Découvrez" ]
                , a [ href "" ]
                    [ text "Vos favoris" ]
                ]
            , form [ onSubmit submitSearchMsg, class "desktop-only" ]
                [ div [ class "search__group" ]
                    [ input
                        [ type_ "search"
                        , value session.search
                        , onInput updateSearchMsg
                        , placeholder "Exemple : Français"
                        ]
                        []
                    , button [ class "search_button" ]
                        [ img [ src "%PUBLIC_URL%/images/icons/32x32/search_32_purple.svg" ] [] ]
                    ]
                ]
            , a [ href "/", class "mobile-only logo" ]
                [ img [ src "%PUBLIC_URL%/images/logos/classea12.svg", class "logo" ] []
                ]
            , div [ class "desktop-only" ]
                [ viewPublishVideoButton
                , loginProfileIcon
                ]
            , button [ class "mobile-only menu-opener" ]
                [ text "Menu"
                , div [][
                    span [][]
                ]
                ]
            , aside [ class "mobile-menu" ]
                [ div []
                    [ viewPublishVideoButton
                    , button [ class "close-mobile-menu" ]
                        [ img [ src "%PUBLIC_URL%/images/icons/24x24/close_24_purple.svg" ] []
                        ]
                    ]
                , nav
                    []
                    [ loginProfileIcon
                    , a [ href "" ]
                        [ img [ src "%PUBLIC_URL%/images/icons/32x32/search_32_white.svg" ] []
                        , text "Recherche"
                        ]
                    , linkMaybeActive Home Route.Home "Accueil"
                    ]
                , div []
                    [ h3 [] [ text "Catégories" ]
                    , nav []
                        (Data.PeerTube.keywordList
                            |> List.map
                                (\( keyword, _ ) ->
                                    let
                                        route =
                                            Route.VideoList <| Route.Keyword keyword
                                    in
                                    linkMaybeActive (VideoList <| Route.Search keyword) route keyword
                                )
                        )
                    , h3 [] [ text "Le projet" ]
                    , nav []
                        [ linkMaybeActive About Route.About "Classe à 12 ?"
                        , linkMaybeActive Participate Route.Participate "Je participe"
                        , a [ href "mailto:classea12@education.gouv.fr" ]
                            [ img [ src "%PUBLIC_URL%/images/icons/32x32/message_32_white.svg" ] []
                            , text "Contactez-nous"
                            ]

                        -- Link to the Mailchimp signup form.
                        , a [ href "http://eepurl.com/gnJbYz" ]
                            [ img [ src "%PUBLIC_URL%/images/icons/32x32/newsletter_32_white.svg" ] []
                            , text "Inscrivez-vous à notre infolettre"
                            ]
                        ]
                    ]
                ]
            ]
        ]


viewContent : List (Html msg) -> Html msg
viewContent body =
    main_ [ class "wrapper" ]
        body


viewFooter : Session -> Html msg
viewFooter session =
    footer [ class "wrapper" ]
        [ a [ href "" ]
            [ img [ alt "Logo 110bis - Lab de l'éducation nationale", src "%PUBLIC_URL%/images/logos/110bis.svg" ]
                []
            ]
        , div []
            [ nav []
                [ a [ Route.href Route.CGU ] [ text "Conditions générales d'utilisation" ]
                , a [ Route.href Route.Convention ] [ text "Charte de bonne conduite" ]
                , a [ Route.href Route.PrivacyPolicy ] [ text "Politique de confidentialité" ]
                ]
            , span [] [ text <| "Version : " ++ session.version ]
            ]
        ]


viewAside : Config msg -> Html msg
viewAside { activePage } =
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
    aside [ class "side-menu desktop-only" ]
        [ a [ href "/" ]
            [ img [ src "%PUBLIC_URL%/images/logos/classea12.svg", class "logo" ] []
            ]
        , nav []
            [ linkMaybeActive Home Route.Home "Accueil"
            , linkMaybeActive (VideoList Route.Latest) (Route.VideoList Route.Latest) "Nouveautés"
            , linkMaybeActive (VideoList Route.Playlist) (Route.VideoList Route.Playlist) "La playlist de la semaine"
            ]
        , div []
            [ h3 [] [ text "Catégories" ]
            , nav []
                (Data.PeerTube.keywordList
                    |> List.map
                        (\( keyword, _ ) ->
                            let
                                route =
                                    Route.VideoList <| Route.Keyword keyword
                            in
                            linkMaybeActive (VideoList <| Route.Search keyword) route keyword
                        )
                )
            , h3 [] [ text "Le projet" ]
            , nav []
                [ linkMaybeActive About Route.About "Classe à 12 ?"
                , linkMaybeActive Participate Route.Participate "Je participe"
                , a [ href "mailto:classea12@education.gouv.fr" ]
                    [ img [ src "%PUBLIC_URL%/images/icons/32x32/message_32_white.svg" ] []
                    , text "Contactez-nous"
                    ]

                -- Link to the Mailchimp signup form.
                , a [ href "http://eepurl.com/gnJbYz" ]
                    [ img [ src "%PUBLIC_URL%/images/icons/32x32/newsletter_32_white.svg" ] []
                    , text "Inscrivez-vous à notre infolettre"
                    ]
                ]
            ]
        ]

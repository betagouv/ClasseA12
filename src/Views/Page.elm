module Views.Page exposing (ActivePage(..), Config, frame)

import Browser exposing (Document)
import Data.PeerTube
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
        [ div [ class "content" ]
            [ viewHeader config pageTitle pageSubTitle
            , viewContent body
            , viewFooter
            ]
        , viewAside config
        ]
    }


viewHeader : Config msg -> String -> String -> Html msg
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
    header []
        [ div [ class "wrapper" ]
            [ img [ alt "Ministère de l'éducation nationale et de la jeunesse", src "" ]
                []
            , nav []
                [ a [ href "" ]
                    [ text "Découvrez" ]
                , a [ href "" ]
                    [ text "Vos favoris" ]
                ]
            , form []
                [ input [ type_ "text" ]
                    []
                , text "  "
                ]
            , div []
                [ a [ class "btn", href "" ]
                    [ text "Partagez une vidéo" ]
                , a [ class "account", href "" ]
                    []
                ]
            ]
        ]


viewContent : List (Html msg) -> Html msg
viewContent body =
    main_ [ class "wrapper" ]
        body


viewFooter : Html msg
viewFooter =
    footer [ class "wrapper" ] []


viewAside : Config msg -> Html msg
viewAside { activePage } =
    let
        linkMaybeActive page route caption =
            nav []
                [ a
                    [ Route.href route
                    , classList
                        [ ( "active", page == activePage )
                        ]
                    ]
                    [ text caption ]
                ]
    in
    aside [ class "side-menu" ]
        [ img [ src "images/logos/classea12.svg" ] []
        , nav []
            [ linkMaybeActive Home Route.Home "Accueil"
            , linkMaybeActive (Search "Nouveautés") (Route.Search Nothing) "Nouveautés"
            ]
        , div []
            [ h3 [] [ text "Catégories" ]
            , nav []
                (Data.PeerTube.keywordList
                    |> List.map
                        (\( keyword, _ ) ->
                            let
                                route =
                                    Route.Search <| Just keyword
                            in
                            linkMaybeActive (Search keyword) route keyword
                        )
                )
            , h3 [] [ text "Le projet" ]
            , nav []
                [ linkMaybeActive About Route.About "Classe à 12 ?"
                , linkMaybeActive Participate Route.Participate "Je participe"
                , a [ href "mailto:classea12@education.gouv.fr" ] [ text "Contactez-nous" ]

                -- Link to the Mailchimp signup form.
                , a [ href "http://eepurl.com/gnJbYz" ] [ text "Inscrivez-vous à notre infolettre" ]
                ]
            ]
        ]

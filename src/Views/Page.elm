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
            ++ [ viewAside config.session ]
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
    [ div [ class "content" ]
        [ header []
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
        , main_ [ class "wrapper" ]
            body
        ]
    ]


viewFooter : Session -> Html msg
viewFooter session =
    footer [ class "wrapper" ] []


viewAside : Session -> Html msg
viewAside session =
    aside [] []

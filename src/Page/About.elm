module Page.About exposing (Model, Msg(..), init, update, view)

import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA exposing (class)
import Page.Common.Components


type alias Model =
    { title : String }


type Msg
    = NoOp


init : Session -> ( Model, Cmd Msg )
init _ =
    ( { title = "Classe à 12 ?" }, Cmd.none )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ _ model =
    ( model, Cmd.none )


view : Session -> Model -> Page.Common.Components.Document Msg
view _ { title } =
    { title = title
    , pageTitle = title
    , pageSubTitle = "Prêt ? Filmez ! Partagez !"
    , body =
        [ H.section [ HA.class "about_content" ]
            [ H.h1 []
                [ H.text "À propos"
                , H.span []
                    [ H.text "de Classe à 12"
                    ]
                ]
            , H.article [ HA.class "about__service" ]
                [ H.img
                    [ HA.src "%PUBLIC_URL%/images/photos/equipe.jpg"
                    , HA.alt ""
                    , HA.class "about__image"
                    ]
                    []
                , H.div [ HA.class "richtext about__text" ]
                    [ H.h3 [ HA.class "title is-3" ] [ H.text "Un nouveau service, pour quoi faire ?" ]
                    , H.p [] [ H.text "Partager pour apprendre et progresser en équipe" ]
                    , H.p [] [ H.text "Ce projet en cours de développement, co-construit avec les enseignants des classes dédoublées (CP et CE1), a pour objectif de valoriser les retours d’expérience et les échanges de pratiques personnalisées, via un produit numérique de type réseau social." ]
                    , H.p [] [ H.text "Que vous soyez novice ou expérimenté, nous vous proposons une plateforme vidéo permettant de partager vos expériences pédagogiques auprès de vos collègues, facilement et dans le respect des pratiques de chacun." ]
                    ]
                ]
            , H.article [ HA.class "about__participate" ]
                [ H.div [ HA.class "about__image" ]
                    [ H.img
                        [ HA.src "%PUBLIC_URL%/images/photos/postits.jpg"
                        , HA.alt ""
                        ]
                        []
                    ]
                , H.div [ HA.class "richtext about__text" ]
                    [ H.h3 [ HA.class "title is-3" ] [ H.text "Comment participer ?" ]
                    , H.p [] [ H.text "Venez comme vous êtes, avec votre envie et vos idées !" ]
                    , H.p [] [ H.text "Vous avez envie d'échanger et de partager des outils, des pratiques, des gestes professionnels avec vos collègues ? Rien de plus simple avec Classe à 12 ! Postez une courte vidéo de 1 à 2 mn en format paysage et c'est parti !" ]
                    , H.p []
                        [ H.text "N'oubliez pas de remplir et de nous envoyer un formulaire de droit à l'image pour vos élèves, les parents ou vous-mêmes, selon la situation, que vous pouvez "
                        , H.a [ HA.href "http://eduscol.education.fr/internet-responsable/ressources/boite-a-outils.html" ] [ H.text "trouver ici." ]
                        ]
                    ]
                ]
            , H.article [ HA.class "about__subject" ]
                [ H.div [ HA.class "about__image" ]
                    [ H.img
                        [ HA.src "%PUBLIC_URL%/images/photos/groupe.jpg"
                        , HA.alt ""
                        ]
                        []
                    ]
                , H.div [ HA.class "richtext about__text " ]
                    [ H.h3 [ HA.class "title is-3" ] [ H.text "Quel sujet traiter dans ma vidéo ?" ]
                    , H.p [] [ H.text "Toute contribution est précieuse, mutualisons nos expériences et nos intelligences !" ]
                    , H.p [] [ H.text "Avec ou sans élève, racontez votre classe, décrivez son aménagement, partagez votre organisation avec vos collègues, montrez une séance pédagogique, parlez d'un jeu ou d'un livre qui vous a plu... tout est permis ! Regardez les exemples déjà proposés sur le site ! Et... si le sujet a déjà été traité, n'hésitez pas à donner votre propre point de vue ! Nous nous enrichirons mutuellement." ]
                    ]
                ]
            , H.article [ HA.class "about__video" ]
                [ H.div [ HA.class "about__image" ]
                    [ H.img
                        [ HA.src "%PUBLIC_URL%/images/photos/mobile.jpg"
                        , HA.alt ""
                        ]
                        []
                    ]
                , H.div [ HA.class "richtext about__text " ]
                    [ H.h3 [ HA.class "title is-3" ] [ H.text "Une vidéo de deux minutes permet d’exprimer l’essentiel." ]
                    , H.p [] [ H.text "L’appropriation de l’activité, des outils, des gestes professionnels devient plus facile" ]
                    , H.p [] [ H.text "Besoin de compléments d’informations ou de précisions? La possibilité d’échanger, et de déposer des pièces jointes sont des fonctionnalités disponibles." ]
                    ]
                ]
            ]
        , H.div [ class "about__end" ]
            [ H.p []
                [ H.text "Que vous soyez novice ou expérimenté"
                , H.br [] []
                , H.text "nous vous invitons à oser dire et agir ensemble"
                , H.br [] []
                , H.text "en tant que professeur expérimentateur"
                ]
            , H.h2 []
                [ H.text "Avec « classe à 12 » nous partageons bien plus que des vidéos,"
                , H.br [] []
                , H.text "alors, osons ensemble !"
                ]
            , H.img
                [ HA.src "%PUBLIC_URL%/images/logos/classea12-dark.svg"
                , HA.alt "Logo Classe à 12"
                , HA.class "about__logo"
                ]
                []
            , H.div [ HA.class "container" ]
                [ H.iframe
                    [ HA.src "https://e.infogram.com/6155d72e-a7c3-4ced-b555-bad597ecf0e9?src=embed"
                    , HA.title "Classe à 12"
                    , HA.width 800
                    , HA.height 400
                    , HA.style "border" "none"
                    , HA.attribute "scrolling" "no"
                    , HA.attribute "frameborder" "0"
                    , HA.attribute "allowfullscreen" "allowfullscreen"
                    ]
                    []
                , H.div
                    []
                    [ H.a
                        [ HA.href "https://infogram.com/6155d72e-a7c3-4ced-b555-bad597ecf0e9"
                        , HA.target "_blank"
                        ]
                        [ H.text "Classe à 12 sur Infogram" ]
                    ]
                ]
            ]
        ]
    }

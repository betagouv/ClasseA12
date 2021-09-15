module Page.About exposing (Model, Msg(..), init, update, view)

import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
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
        [ H.div [ HA.class "section article article__full" ]
            [ H.div [ HA.class "article__content" ]
                [ H.div [ HA.class "container" ]
                    [ H.div [ HA.class "article__image" ]
                        [ H.img
                            [ HA.src "%PUBLIC_URL%/images/photos/photo_de_classe.jpg"
                            , HA.alt "Photo d'élèves dans une classe"
                            ]
                            []
                        ]
                    , H.div [ HA.class "richtext" ]
                        [ H.h3 [ HA.class "title is-3" ] [ H.text "Un nouveau service, pour quoi faire ?" ]
                        , H.em [] [ H.text "Partager pour apprendre et progresser en équipe" ]
                        , H.p [] [ H.text "Ce projet en cours de développement, co-construit avec les enseignants des classes dédoublées (CP et CE1), a pour objectif de valoriser les retours d’expérience et les échanges de pratiques personnalisées, via un produit numérique de type réseau social." ]
                        , H.p [] [ H.text "Que vous soyez novice ou expérimenté, nous vous proposons une plateforme vidéo permettant de partager vos expériences pédagogiques auprès de vos collègues, facilement et dans le respect des pratiques de chacun." ]
                        ]
                    ]
                , H.div [ HA.class "container" ]
                    [ H.div [ HA.class "article__image" ]
                        [ H.img
                            [ HA.src "%PUBLIC_URL%/images/photos/Nicolas_smartphone.jpg"
                            , HA.alt "Photo de Nicolas Leyri en train de se filmer sur son smartphone"
                            ]
                            []
                        ]
                    , H.div [ HA.class "richtext" ]
                        [ H.h3 [ HA.class "title is-3" ] [ H.text "Comment participer ?" ]
                        , H.em [] [ H.text "Venez comme vous êtes, avec votre envie et vos idées !" ]
                        , H.p [] [ H.text "Vous avez envie d'échanger et de partager des outils, des pratiques, des gestes professionnels avec vos collègues ? Rien de plus simple avec Classe à 12 ! Postez une courte vidéo de 1 à 2 mn en format paysage et c'est parti !" ]
                        , H.p []
                            [ H.text "N'oubliez pas de remplir et de nous envoyer un formulaire de droit à l'image pour vos élèves, les parents ou vous-mêmes, selon la situation, que vous pouvez "
                            , H.a [ HA.href "http://eduscol.education.fr/internet-responsable/ressources/boite-a-outils.html" ] [ H.text "trouver ici." ]
                            ]
                        ]
                    ]
                , H.div [ HA.class "container" ]
                    [ H.div [ HA.class "article__image" ]
                        [ H.img
                            [ HA.src "%PUBLIC_URL%/images/photos/Casier_rangement_feutres.jpg"
                            , HA.alt "Photo d'un casier de rangements de feutres de couleur"
                            ]
                            []
                        ]
                    , H.div [ HA.class "richtext" ]
                        [ H.h3 [ HA.class "title is-3" ] [ H.text "Quel sujet traiter dans ma vidéo ?" ]
                        , H.em [] [ H.text "Toute contribution est précieuse, mutualisons nos expériences et nos intelligences !" ]
                        , H.p [] [ H.text "Avec ou sans élève, racontez votre classe, décrivez son aménagement, partagez votre organisation avec vos collègues, montrez une séance pédagogique, parlez d'un jeu ou d'un livre qui vous a plu... tout est permis ! Regardez les exemples déjà proposés sur le site ! Et... si le sujet a déjà été traité, n'hésitez pas à donner votre propre point de vue ! Nous nous enrichirons mutuellement." ]
                        ]
                    ]
                ]
            , H.div [ HA.class "container" ]
                [ H.div [ HA.class "richtext" ]
                    [ H.h3 [ HA.class "title is-3", HA.id "statistiques" ] [ H.text "Statistiques" ]
                    ]
                , H.iframe
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

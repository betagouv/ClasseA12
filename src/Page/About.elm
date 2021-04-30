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
    ( { title = "Devoirs Faits" }, Cmd.none )


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
                        , H.p [] [ H.text "Ce projet en cours de développement, co-construit avec les enseignants de collège, des CPE, des AED et des chefs d’établissement, a pour objectif de faciliter le partage de ressources et de pratiques mises en œuvre dans le cadre du dispositif “Devoirs faits” au collège." ]
                        , H.p [] [ H.text "Vous êtes un acteur de terrain engagé dans le dispositif ? Que vous soyez novice ou expérimenté, nous vous proposons une plateforme vidéo permettant de partager vos initiatives, d’illustrer vos actions et d’inspirer ainsi vos collègues partout en France, facilement et dans le respect des pratiques de chacun." ]
                        ]
                    ]
                , H.div [ HA.class "container" ]
                    [ H.div [ HA.class "article__image" ]
                        [ H.img
                            [ HA.src "%PUBLIC_URL%/images/photos/Camille_post-its.jpg"
                            , HA.alt "Photo de Camille Martinelli plaçant des post-its"
                            ]
                            []
                        ]
                    , H.div [ HA.class "richtext" ]
                        [ H.h3 [ HA.class "title is-3" ] [ H.text "Comment participer ?" ]
                        , H.em [] [ H.text "Venez comme vous êtes, avec votre envie et vos idées !" ]
                        , H.p [] [ H.text "Vous avez envie d'échanger et de partager des outils, des pratiques, des gestes professionnels avec vos collègues ? Rien de plus simple avec le site Devoirs Faits : la communauté ! Postez une courte vidéo de 1 à 2 mn en format paysage et c'est parti !" ]
                        , H.p []
                            [ H.text "N'oubliez pas de remplir et de nous envoyer un formulaire de droit à l'image pour vos élèves, les parents ou vous-mêmes, selon la situation, que vous pouvez trouver ici : "
                            , H.a [ HA.href "https://devoirs-faits-communaute.beta.gouv.fr/documents/Autorisation-captation-image-majeur_2017.pdf" ] [ H.text "autorisation adulte" ]
                            , H.text " - "
                            , H.a [ HA.href "https://devoirs-faits-communaute.beta.gouv.fr/documents/Autorisation-captation-image-mineur_2017.pdf" ] [ H.text "autorisation mineur" ]
                            ]
                        ]
                    ]
                , H.div [ HA.class "container" ]
                    [ H.div [ HA.class "article__image" ]
                        [ H.img
                            [ HA.src "%PUBLIC_URL%/images/photos/eleve_visio.jpg"
                            , HA.alt "Deux élèves en visio"
                            ]
                            []
                        ]
                    , H.div [ HA.class "richtext" ]
                        [ H.h3 [ HA.class "title is-3" ] [ H.text "Quel sujet traiter dans ma vidéo ?" ]
                        , H.em [] [ H.text "Toute contribution est précieuse, mutualisons nos expériences et nos intelligences !" ]
                        , H.p [] [ H.text "Avec ou sans élève, racontez votre mise en œuvre du dispositif, décrivez son aménagement, partagez votre organisation avec vos collègues, montrez une séance en groupes...tout est permis ! Regardez les exemples déjà proposés sur le site ! Et... si le sujet a déjà été traité, n'hésitez pas à donner votre propre point de vue ! Nous nous enrichirons mutuellement." ]
                        ]
                    ]
                , H.div [ HA.class "richtext" ]
                    [ H.h3 [ HA.class "title is-3" ] [ H.text "Devoirs Faits, un projet en construction" ]
                    , H.em [] [ H.text "Un service en cours d’élaboration pour s’adapter à vos attentes !" ]
                    , H.p [] [ H.text "Le présent prototype de site est une version bêta : cela veut dire qu’il continuera à évoluer en fonction des retours des usagers pour répondre au mieux à leurs besoins." ]
                    , H.p []
                        [ H.text "Ce projet est accompagné par le 110 bis, lab d’innovation de l’Education nationale, et porté par une intrapreneure issue de l’académie de Créteil. Accédez à "
                        , H.a [ HA.href "https://www.education.gouv.fr/presentation-du-110-bis-lab-d-innovation-de-l-education-nationale-11756" ] [ H.text "cet article de présentation" ]
                        , H.text " pour en savoir plus."
                        ]
                    , H.p []
                        [ H.text "Ce prototype s’inscrit dans le dispositif "
                        , H.a [ HA.href "https://www.education.gouv.fr/devoirs-faits-12962" ] [ H.text "Devoirs Faits" ]
                        , H.text " porté par le ministère de l’Education nationale, de la Jeunesse et des Sports."
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

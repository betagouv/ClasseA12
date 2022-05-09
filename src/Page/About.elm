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
    ( { title = "Devoirs Faits ?" }, Cmd.none )


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
                    [ H.text "de Devoirs Faits"
                    ]
                ]
            , H.article [ HA.class "about__service" ]
                [ H.img
                    [ HA.src "%PUBLIC_URL%/images/photos/photo_de_classe.jpg"
                    , HA.alt ""
                    , HA.class "about__image"
                    ]
                    []
                , H.div [ HA.class "richtext about__text" ]
                    [ H.h3 [ HA.class "title is-3" ] [ H.text "Un nouveau service, pour quoi faire ?" ]
                    , H.p [] [ H.text "Partager pour apprendre et progresser en équipe" ]
                    , H.p [] [ H.text "Ce projet en cours de développement, co-construit avec les enseignants des classes dédoublées (grandes sections, CP et CE1), a pour objectif de valoriser les retours d’expérience et les échanges de pratiques personnalisées, via un produit numérique de type réseau social." ]
                    , H.p [] [ H.text "Que vous soyez novice ou expérimenté, nous vous proposons une plateforme vidéo permettant de partager vos expériences pédagogiques auprès de vos collègues, facilement et dans le respect des pratiques de chacun." ]
                    ]
                ]
            , H.article [ HA.class "about__participate" ]
                [ H.div [ HA.class "about__image" ]
                    [ H.img
                        [ HA.src "%PUBLIC_URL%/images/photos/Camille_post-its.jpg"
                        , HA.alt ""
                        ]
                        []
                    ]
                , H.div [ HA.class "richtext about__text" ]
                    [ H.h3 [ HA.class "title is-3" ] [ H.text "Comment participer ?" ]
                    , H.p [] [ H.text "Venez comme vous êtes, avec votre envie et vos idées !" ]
                    , H.p [] [ H.text "Vous avez envie d'échanger et de partager des outils, des pratiques, des gestes professionnels avec vos collègues ? Rien de plus simple avec le site Devoirs Faits : la communauté ! Postez une courte vidéo de 1 à 2 mn en format paysage et c'est parti !" ]
                    , H.p []
                        [ H.text "N'oubliez pas de remplir et de nous envoyer un formulaire de droit à l'image pour vos élèves, les parents ou vous-mêmes, selon la situation, que vous pouvez trouver ici : "
                        , H.a [ HA.href "https://devoirs-faits-communaute.beta.gouv.fr/documents/Autorisation-captation-image-majeur_2017.pdf" ] [ H.text "autorisation adulte" ]
                        ,H.text " - "
                        ,H.a [ HA.href "https://devoirs-faits-communaute.beta.gouv.fr/documents/Autorisation-captation-image-mineur_2017.pdf" ] [ H.text "autorisation mineur" ]
                        ]
                    ]
                ]
            , H.article [ HA.class "about__subject" ]
                [ H.div [ HA.class "about__image" ]
                    [ H.img
                        [ HA.src "%PUBLIC_URL%/images/photos/eleve_visio.jpg"
                        , HA.alt ""
                        ]
                        []
                    ]
                , H.div [ HA.class "richtext about__text " ]
                    [ H.h3 [ HA.class "title is-3" ] [ H.text "Quel sujet traiter dans ma vidéo ?" ]
                    , H.p [] [ H.text "Toute contribution est précieuse, mutualisons nos expériences et nos intelligences !" ]
                    , H.p [] [ H.text "Avec ou sans élève, racontez votre mise en œuvre du dispositif, décrivez son aménagement, partagez votre organisation avec vos collègues, montrez une séance en groupes...tout est permis ! Regardez les exemples déjà proposés sur le site ! Et... si le sujet a déjà été traité, n'hésitez pas à donner votre propre point de vue ! Nous nous enrichirons mutuellement." ]
                    ]
                ]
            , H.article [ HA.class "about__DF" ]
                [ H.div [ HA.class "about__image" ]
                    [ H.img
                        [ HA.src "%PUBLIC_URL%/images/logos/devoirsfaits-dark.svg"
                        , HA.alt ""
                        ]
                        []
                    ]
                , H.div [ HA.class "richtext about__text " ]
                    [ H.h3 [ HA.class "title is-3" ] [ H.text "Devoirs Faits, un projet en construction." ]
                    , H.p [] [ H.text "Un service en cours d’élaboration pour s’adapter à vos attentes !" ]
                    , H.p [] [ H.text "Le présent prototype de site est une version bêta : cela veut dire qu’il continuera à évoluer en fonction des retours des usagers pour répondre au mieux à leurs besoins." ]
                    , H.p [] [ H.text "Ce projet est accompagné par le 110 bis, lab d’innovation de l’Education nationale, et porté par une intrapreneure issue de l’académie de Créteil. Accédez à cet article de présentation pour en savoir plus." ]
                    , H.p [] [ H.text "Ce prototype s’inscrit dans le dispositif Devoirs Faits porté par le ministère de l’Education nationale, de la Jeunesse et des Sports." ]
                    ]
                ]
            ]
        ]
    }

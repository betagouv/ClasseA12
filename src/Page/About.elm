module Page.About exposing (Model, Msg(..), init, update, view)

import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA


type alias Model =
    {}


type Msg
    = NoOp


init : Session -> ( Model, Cmd Msg )
init session =
    ( {}, Cmd.none )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    ( model, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view _ model =
    ( "Classe à 12 ?"
    , [ H.div []
            [ H.h1 [ HA.class "title" ] [ H.text "Classe à 12 ?" ]
            , H.h2 [ HA.class "subtitle" ] [ H.text "Prêt.e ? Filmez ! Partagez !" ]
            , H.div [ HA.class "columns" ]
                [ H.div [ HA.class "column is-narrow" ]
                    [ H.img
                        [ HA.src "http://res.cloudinary.com/hrscywv4p/image/upload/c_limit,fl_lossy,h_1440,w_720,f_auto,q_auto/v1/1436014/aaa54f1f-f314-4d46-9fa5-f3b48835db45_htkbm2.jpg"
                        , HA.alt "Photo de Malika Alouani et Nicolas Leyri"
                        ]
                        []
                    ]
                , H.div [ HA.class "column" ]
                    [ H.h3 [ HA.class "title is-3" ] [ H.text "Qui sommes-nous ?" ]
                    , H.em [] [ H.text "« Ne vous laissez pas arrêter par ceux qui, devant l’imperfection de ce que vous réalisez, ne manqueront pas de prôner les méthodes du passé qu’ils voudraient empêcher de mourir définitivement » (Célestin Freinet)." ]
                    , H.p [] [ H.text "Malika : enseignante formatrice, conseillère au numérique à la Direction du numérique éducatif et à la délégation académique au numérique de Versailles, j’ai accepté de quitter la classe pour accompagner les nouveaux usages pédagogiques avec le numérique." ]
                    , H.p [] [ H.text "Nicolas : coordonnateur REP à Fontenay-sous-Bois, je suis passionné par les problématiques de l’éducation prioritaire, l’innovation, les nouvelles technologies et la vidéo." ]
                    , H.em [] [ H.text "« Rien n’est plus fort en ce monde qu’une idée dont l’heure est arrivée » (Victor Hugo)." ]
                    ]
                ]
            , H.div [ HA.class "columns" ]
                [ H.div [ HA.class "colum" ]
                    [ H.h3 [ HA.class "title is-3" ] [ H.text "Un nouveau service, pour quoi faire ?" ]
                    , H.em [] [ H.text "Partager pour apprendre et progresser en équipe" ]
                    , H.p [] [ H.text "Ce projet en cours de développement, co-construit avec les enseignants des classes de CP à 12, a pour objectif de valoriser les retours d’expérience et les échanges de pratiques personnalisées, via un produit numérique de type réseau social." ]
                    , H.p [] [ H.text "Que vous soyez novice ou expérimenté, nous vous proposons une plateforme vidéo permettant de partager vos expériences pédagogiques auprès de vos collègues, facilement et dans le respect des pratiques de chacun." ]
                    ]
                , H.div [ HA.class "column is-narrow" ]
                    [ H.img
                        [ HA.src "http://res.cloudinary.com/hrscywv4p/image/upload/c_limit,fl_lossy,h_1440,w_720,f_auto,q_auto/v1/1436014/IMG_5702_nv6pjl.png"
                        , HA.alt "Photo d'élèves dans une classe"
                        ]
                        []
                    ]
                ]
            , H.div [ HA.class "columns" ]
                [ H.div [ HA.class "column is-narrow" ]
                    [ H.img
                        [ HA.src "http://res.cloudinary.com/hrscywv4p/image/upload/c_limit,fl_lossy,h_1440,w_720,f_auto,q_auto/v1/1436014/2eaa8893-502a-439f-90ba-e0842eb72284_h4p2cg.jpg"
                        , HA.alt "Photo de Nicolas Leyri en train de se filmer sur son smartphone"
                        ]
                        []
                    ]
                , H.div [ HA.class "column" ]
                    [ H.h3 [ HA.class "title is-3" ] [ H.text "Comment participer ?" ]
                    , H.em [] [ H.text "Venez comme vous êtes, avec votre envie et vos idées !" ]
                    , H.p [] [ H.text "Vous avez expérimenté un scénario gagnant, vous avez tout simplement envie de partager et d'échanger avec vos collègues ? Rien de plus simple avec Classe à 12 ! Postez une courte vidéo de 1 à 2 mn en format paysage et c'est parti !" ]
                    , H.p [] [ H.text "N'oubliez pas de remplir et de nous envoyer un formulaire de droit à l'image pour vos élèves, les parents ou vous-mêmes, selon la situation, que vous pouvez" ]
                    , H.a [ HA.href "http://eduscol.education.fr/internet-responsable/ressources/boite-a-outils.html" ] [ H.text "trouver ici." ]
                    ]
                ]
            , H.div [ HA.class "columns" ]
                [ H.div [ HA.class "column" ]
                    [ H.h3 [ HA.class "title is-3" ] [ H.text "Quel sujet traiter dans ma vidéo ?" ]
                    , H.em [] [ H.text "Toute contribution est précieuse, mutualisons nos expériences et nos intelligences !" ]
                    , H.p [] [ H.text "Avec ou sans élève, racontez votre classe, décrivez son aménagement, partagez votre organisation avec vos collègues, montrez une séance pédagogique, parlez d'un jeu ou d'un livre qui vous a plu... tout est permis ! Regardez les exemples déjà proposés sur le site ! Et... si le sujet a déjà été traité, n'hésitez pas à donner votre propre point de vue ! Nous nous enrichirons mutuellement." ]
                    ]
                , H.div [ HA.class "column is-narrow" ]
                    [ H.img
                        [ HA.src "http://res.cloudinary.com/hrscywv4p/image/upload/c_limit,fl_lossy,h_1440,w_720,f_auto,q_auto/v1/1436014/9ba429e2-d343-4e7e-a6de-fc0918beff54_rskzrf.png"
                        , HA.alt "Photo d'un casier de rangements de feutres de couleur"
                        ]
                        []
                    ]
                ]
            ]
      ]
    )

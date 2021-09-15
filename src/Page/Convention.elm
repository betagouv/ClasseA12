module Page.Convention exposing (Model, Msg(..), init, update, view)

import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Page.Common.Components


type alias Model =
    { title : String }


type Msg
    = Noop


init : Session -> ( Model, Cmd Msg )
init _ =
    ( { title = "Charte de bonne conduite du site" }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ _ model =
    ( model, Cmd.none )


view : Session -> Model -> Page.Common.Components.Document Msg
view _ { title } =
    { title = title
    , pageTitle = "Charte de bonne conduite"
    , pageSubTitle = "du site « Devoirs Faits » du Ministère de l’éducation et de la jeunesse"
    , body =
        [ H.div [ HA.class "section convention" ]
            [ H.div [ HA.class "container" ]
                [ H.h1 [] [ H.text "Définition du projet :" ]
                , H.p [] [ H.text "Ce service est un réseau social à base de vidéos de pratiques pédagogiques entre les acteurs du dispositif «\u{00A0}Devoirs Faits\u{00A0}» (professeurs, A.E.D., C.P.E., personnels de direction). Il a pour objectif de faciliter les échanges entre pairs et de mutualiser les pratiques." ]
                , H.p [] [ H.text "Le site «\u{00A0}Devoirs Faits\u{00A0}» est un espace commun : tous les usagers et partenaires de Devoirs Faits sont à la fois dépositaires et bénéficiaires des ressources et services proposés. C’est  un écosystème apprenant : les acteurs qui gravitent autour de Devoirs Faits\u{00A0}s’enrichissent mutuellement et nourrissent la plateforme de leurs productions." ]
                , H.p [] [ H.text "Le site Devoirs Faits : propose un cadre neutre d’échanges horizontaux : les échanges se font dans un esprit d’ouverture et de bienveillance entre pairs." ]
                , H.h1 [] [ H.text "Conditions d’utilisation :" ]
                , H.ul []
                    [ H.li [] [ H.text "Les droits d’utilisation nécessitent la validation préalable des conditions générales d’utilisation figurant sur le site." ]
                    , H.li [] [ H.text "Le site n’a pas pour vocation de contrôler ni de valider les productions." ]
                    , H.li [] [ H.text "Les vidéos non conformes aux programmes ou à une éthique professionnelle feront l’objet d’une non publication ou dé-publication." ]
                    , H.li [] [ H.text "Vous trouverez ci-dessous, les points importants à respecter pour garantir la qualité et le bon fonctionnement des échanges. En cas de non respect des points suivants, vous engagez votre entière responsabilité." ]
                    , H.li [] [ H.text "L’enseignant inscrit sur le site est le seul responsable du respect des droits à l’image et des droits d’auteurs relatives aux vidéos." ]
                    , H.li [] [ H.text "L’enseignant aura fait signer les documents nécessaires à l’autorisation de publication aux personnes apparaissant sur les vidéos publiés." ]
                    , H.li [] [ H.text "Seuls les personnels de l’éducation nationale peuvent créer un compte utilisateur avec leur adresse mail académique. Seules les personnes inscrites peuvent publier des vidéos et profiter des fonctionnalités de réseautage." ]
                    , H.li [] [ H.text "Nous vous invitons à veiller à ne pas utiliser de termes ou expressions susceptibles de choquer les autres Utilisateurs, d'être perçus comme provocants ou obscènes, attentatoires aux bonnes mœurs, diffamatoires, insultants, discriminatoires ou incitant à la haine raciale, religieuse, politique ou autre, que ces termes ou expressions soient proscrits par la loi ou simplement contraires au respect et à la dignité de la personne humaine." ]
                    , H.li [] [ H.text "Si vous avez le sentiment ou si vous constatez qu'un Utilisateur ne respecte pas les conditions énoncées dans la présente charte, auxquelles il a pourtant souscrit lors de son inscription, ou que son comportement est répréhensible au regard de la loi ou de la morale, vous devez le signaler au modérateur du Site Internet en utilisant le formulaire de contact. Le modérateur pourra, le cas échéant, adresser un avertissement à l'utilisateur en cause et/ou arrêter sa connexion Membre." ]
                    ]
                , H.h1 [] [ H.text "Références juridiques utilisées pour la rédaction de la présente charte :" ]
                , H.ul []
                    [ H.li []
                        [ H.a [ HA.href "http://eduscol.education.fr/cid57095/charte-usage-des-tic.html#lien0" ]
                            [ H.text "Guide d’élaboration d’une charte « Eduscol »" ]
                        ]
                    , H.li []
                        [ H.a [ HA.href "https://www.cnil.fr/fr/principes-cles/guide-de-la-securite-des-donnees-personnelles" ]
                            [ H.text "Guide de la sécurité des données personnelles" ]
                        ]
                    ]
                ]
            ]
        ]
    }

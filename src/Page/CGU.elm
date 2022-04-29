module Page.CGU exposing (Model, Msg(..), init, update, view)

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
    ( { title = "Conditions générales d’utilisation" }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ _ model =
    ( model, Cmd.none )


view : Session -> Model -> Page.Common.Components.Document Msg
view _ { title } =
    { title = title
    , pageTitle = title
    , pageSubTitle = ""
    , body =
        [ H.div [ HA.class "section " ]
            [ H.div [ HA.class "container" ]
                [ H.p [] [ H.text "Le site «\u{00A0}Devoirs Faits\u{00A0}» est un projet en construction édité dans le cadre d’une Startup d’État portée par le laboratoire d’innovation du Ministère (Lab110bis), la Direction interministérielle des systèmes d'information et de communication de l'État (DINSIC)." ]
                , H.p [] [ H.text "Ce projet actuellement hébergé par les services de beta.gouv.fr, est en lien avec le réseau des incubateurs de Startup d’État." ]
                , H.p [] [ H.text "Le site est édité et développé par la Direction interministérielle du numérique et du système d'information et de communication de l'Etat (DINSIC) au sein du Secrétariat général pour la modernisation de l'action publique (SGMAP)." ]
                , H.p [] [ H.text "Toute utilisation du site «\u{00A0}Devoirs Faits\u{00A0}»  est subordonnée au respect des présentes conditions générales d'utilisation (CGU)." ]
                , H.h2 [] [ H.text "Est défini comme :" ]
                , H.p []
                    [ H.strong [] [ H.text "API (web) : " ]
                    , H.text "interface web structurée permettant d'interagir automatiquement avec un système d'information, qui inclut généralement la récupération de données à la demande ;"
                    ]
                , H.p []
                    [ H.strong [] [ H.text "Administrateur : " ]
                    , H.text "les administrateurs du site, responsables d’édition."
                    ]
                , H.p []
                    [ H.strong [] [ H.text "Jeu de données : " ]
                    , H.text "ensemble cohérent de ressources ou d'informations (fichiers de données, fichiers d'explications, API, lien...) et de métadonnées (présentation, date de publication, mots-clefs, couverture géographique/temporelle...), sur un thème donné ;"
                    ]
                , H.p []
                    [ H.strong [] [ H.text "Utilisateur : " ]
                    , H.text "Ensemble des professeurs de CP et CE1 des classes dédoublées de l’éducation nationale accédant au site afin de consulter ou poster des médias."
                    ]
                , H.h2 [] [ H.text "Objet" ]
                , H.p [] [ H.text "Le site répond à un objectif d’accompagnement du dispositif de classe dédoublée en éducation prioritaire lancée par le ministre de l’Éducation nationale et de la jeunesse." ]
                , H.p [] [ H.text "Il permet :" ]
                , H.ul []
                    [ H.li [] [ H.text "la publication par des professeurs de vidéos concernant des pratiques pédagogiques," ]
                    , H.li [] [ H.text "la consultation de ces données par tout Utilisateur," ]
                    , H.li [] [ H.text "une discussion autour des données, ainsi que la diffusion de Jeux de données enrichis ou de réutilisations." ]
                    ]
                , H.h2 [] [ H.text "Fonctionnalités" ]
                , H.p [] [ H.text "L'utilisation du site est libre et gratuite." ]
                , H.h2 [] [ H.text "Consultation et téléchargement des données" ]
                , H.p [] [ H.text "La consultation des contenus mis à disposition ne nécessite aucune inscription préalable." ]
                , H.p [] [ H.text "Le dépôt de vidéo nécessite une inscription préalable à l’aide d’une adresse professionnelle académique." ]
                , H.p [] [ H.text "Les médias sont conservés pour une durée déterminée définie dans les conditions préalables d’inscription." ]
                , H.p [] [ H.text "Toutes les vidéos sont protégées et publiées selon les conditions définies par les mentions suivantes :" ]
                , H.p []
                    [ H.a
                        [ HA.rel "license"
                        , HA.href "http://creativecommons.org/licenses/by/4.0/deed.fr"
                        ]
                        [ H.img
                            [ HA.alt "Licence Creative Commons"
                            , HA.style "border-width" "0"
                            , HA.src "https://i.creativecommons.org/l/by/4.0/88x31.png"
                            ]
                            []
                        ]
                    ]
                , H.h2 [] [ H.text "Inscription sur le site et fonctionnalités liées" ]
                , H.p [] [ H.text "Tout Utilisateur peut contribuer et poster des vidéos, en publiant des jeux de données, des réutilisations de ceux-ci, ressources et commentaires relatifs aux Jeux de données." ]
                , H.p [] [ H.text "Pour ce faire, l'Utilisateur s'inscrit sur le site. Cette inscription est propre à sa personne et non à l'entité ou personne morale qu'il représente." ]
                , H.p [] [ H.text "En s'inscrivant, l'Utilisateur crée un profil sur le site. Pour plus de précisions, voir la rubrique Vie privée." ]
                , H.p [] [ H.text "Dès validation de son inscription, L’Utilisateur dispose du droit de poster des médias. Ces derniers sont modérés par les Administrateurs avant toute diffusion publique. " ]
                , H.p [] [ H.text "Enfin, il peut participer au contrôle de la qualité du site en signalant aux Administrateurs les contenus n'ayant pas vocation à y figurer (illicites ou contraires aux CGU). " ]
                , H.h2 [] [ H.text "Evolution des conditions d'utilisation" ]
                , H.p [] [ H.text "Les termes des présentes conditions d'utilisation peuvent être amendés à tout moment, sans préavis, en fonction des modifications apportées au site, de l'évolution de la législation ou pour tout autre motif jugé nécessaire." ]
                , H.h2 [] [ H.text "Vie privée" ]
                , H.h3 [] [ H.text "Cookies" ]
                , H.p [] [ H.text "Le site dépose des cookies de mesure d'audience (nombre de visites, pages consultées), respectant les conditions d'exemption du consentement de l'internaute définies par la recommandation « Cookies » de la Commission nationale informatique et libertés (CNIL) ; il utilise Piwik, un outil libre, paramétré pour ce faire. Cela signifie, notamment, que ces cookies ne servent qu'à la production de statistiques anonymes et ne permettent pas de suivre la navigation de l'internaute sur d'autres sites." ]
                , H.p [] [ H.text "Le site dépose également des cookies de navigation, aux fins strictement techniques, qui ne sont pas conservés." ]
                , H.p [] [ H.text "La consultation du site n'est pas affectée lorsque les Utilisateurs utilisent des navigateurs désactivant les cookies." ]
                , H.h3 [] [ H.text "Données à caractère personnel" ]
                , H.p [] [ H.text "La consultation des jeux de données (y compris leur téléchargement) ne nécessite pas de s'inscrire, ni de s'authentifier." ]
                , H.p [] [ H.text "L'inscription sur le site nécessite que l'Utilisateur communique ses prénom et nom, ainsi que son courriel professionnel. «\u{00A0}Devoirs Faits\u{00A0}» s'engage à prendre toutes les mesures nécessaires permettant de garantir la sécurité et la confidentialité du courriel de l'Utilisateur. Celui-ci n'est jamais communiqué à des tiers, en dehors des cas prévus par la loi." ]
                , H.p [] [ H.text "La page de profil de l'Utilisateur comprend ses prénom et nom et des éléments sur son activité (niveau de classe, profil professeur ou formateur). Cette page n'est pas référencée par le moteur de recherche du site." ]
                , H.p [] [ H.text "L'historique de consultation de l'Utilisateur n'est jamais rendu public, ni communiqué à des tiers, en dehors des cas prévus par la loi." ]
                , H.p []
                    [ H.text "En application de la loi n° 78-17 du 6 janvier 1978 relative à l'informatique, aux fichiers et aux libertés, l'Utilisateur dispose d'un droit d'accès, de rectification et d'opposition auprès de «\u{00A0}Devoirs Faits\u{00A0}». Ce droit s'exerce par courriel adressé à "
                    , H.a [ HA.href "mailto:nicolas.leyri@beta.gouv.fr?subject=droit d'accès, rectification ou opposition" ] [ H.text "nicolas.leyri@beta.gouv.fr" ]
                    , H.text "."
                    ]
                , H.p []
                    [ H.text "Conformément à la loi n° 78-17 du 6 janvier 1978 relative à l'informatique, aux fichiers et aux libertés, toute personne dont les données nominatives figurent dans «\u{00A0}Devoirs Faits\u{00A0}» ou sont utilisées de toute autre manière dans le cadre du présent site, dispose des droits suivants qu’elle peut exercer en prenant contact auprès du délégué à la protection des données (DPO) à l’adresse suivante : "
                    , H.a [ HA.href "mailto:nicolas.leyri@beta.gouv.fr" ] [ H.text "nicolas.leyri@beta.gouv.fr" ]
                    , H.text "."
                    ]
                , H.ul []
                    [ H.li [] [ H.text "droit d’accès, de rectification et d’opposition au traitement de ses données ;" ]
                    , H.li [] [ H.text "droit à la limitation du traitement de ses données ;" ]
                    , H.li [] [ H.text "droit à la portabilité de ses données ;" ]
                    , H.li [] [ H.text "droit à l’effacement et à l’oubli numérique." ]
                    ]
                , H.p []
                    [ H.text "Les Administrateurs du projet «\u{00A0}Devoirs Faits\u{00A0}» veillent actuellement à sa mise en conformité aux nouvelles règles introduites par le « Règlement (UE) 2016/679 du Parlement européen et du Conseil du 27 avril 2016 relatif à la protection des personnes physiques à l'égard du traitement des données à caractère personnel et à la libre circulation de ces données, et abrogeant la directive 95/46/CE » consultable sur le site de la CNIL à l’adresse suivante "
                    , H.a [ HA.href "https://www.cnil.fr/fr/reglement-europeen-protection-donnees" ] [ H.text "https://www.cnil.fr/fr/reglement-europeen-protection-donnees" ]
                    , H.text "."
                    ]
                , H.h2 [] [ H.text "Textes de référence" ]
                , H.p []
                    [ H.a [ HA.href "https://www.legifrance.gouv.fr/affichCode.do%3Bjsessionid=2B8CFC0D49E08E4D1843153F6E476CA7.tpdila11v_2?idSectionTA=LEGISCTA000031367685&cidTexte=LEGITEXT000031366350&dateTexte=20170808" ] [ H.text "Livre III du code des relations entre le public et l'administration" ]
                    , H.br [] []
                    , H.a [ HA.href "https://www.legifrance.gouv.fr/affichTexte.do?cidTexte=JORFTEXT000000886460" ] [ H.text "Loi n° 78-17 du 6 janvier 1978 relative à l'informatique, aux fichiers et aux libertés" ]
                    , H.br [] []
                    , H.a [ HA.href "https://www.legifrance.gouv.fr/affichTexte.do?cidTexte=JORFTEXT000000801164" ] [ H.text "Loi n° 2004-575 du 21 juin 2004 pour la confiance dans l'économie numérique" ]
                    , H.br [] []
                    , H.a [ HA.href "https://www.legifrance.gouv.fr/affichTexte.do?cidTexte=JORFTEXT000033202746&categorieLien=id" ] [ H.text "Loi n° 2016-1321 du 7 octobre 2016 pour une République numérique" ]
                    ]
                , H.h2 [] [ H.text "Mentions légales" ]
                , H.h3 [] [ H.text "Editeurs" ]
                , H.p []
                    [ H.text "Incubateur de services numériques de la Direction interministérielle du numérique et du système d'information et de communication de l'État (DINSIC)."
                    , H.br [] []
                    , H.text "20, avenue de Ségur – 75007 Paris."
                    ]
                , H.p []
                    [ H.text "Laboratoire de l’innovation de l’Education Nationale (Lab110bis)."
                    , H.br [] []
                    , H.text "110, rue de Grenelle – 75007 Paris"
                    ]
                , H.h3 [] [ H.text "Responsables de la publication" ]
                , H.p []
                    [ H.text "Nicolas Leyri - Intrapreneur Startup d’État Devoirs Faits"
                    , H.br [] []
                    , H.text "Malika Alouani - Intrapreneur Startup d’État Devoirs Faits"
                    ]
                , H.h3 [] [ H.text "Prestataire d'hébergement frontend" ]
                , H.p []
                    [ H.text "ALWAYSDATA, SARL"
                    , H.br [] []
                    , H.text "RCS de Paris sous le numéro 492 893 490"
                    , H.br [] []
                    , H.text "Siège social : 62 rue Tiquetonne – 75002 Paris"
                    ]
                , H.h3 [] [ H.text "Prestataire d'hébergement backend" ]
                , H.p []
                    [ H.text "ENIX"
                    , H.br [] []
                    , H.text "RCS de Paris sous le numéro 481 912 970"
                    , H.br [] []
                    , H.text "Siège social : 275 rue Saint Denis – 75002 Paris"
                    ]
                ]
            ]
        ]
    }

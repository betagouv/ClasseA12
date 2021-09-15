module Page.PrivacyPolicy exposing (Model, Msg(..), init, update, view)

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
    ( { title = "Politique de confidentialité" }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ _ model =
    ( model, Cmd.none )


view : Session -> Model -> Page.Common.Components.Document Msg
view _ { title } =
    { title = title
    , pageTitle = "Politique de confidentialité"
    , pageSubTitle = "suivi d'audience et vie privée"
    , body =
        [ H.div [ HA.class "section " ]
            [ H.div [ HA.class "container" ]
                [ H.h2 []
                    [ H.text "Cookies déposés et opt-out" ]
                , H.p [] [ H.text "Ce site dépose un petit fichier texte (un « cookie ») sur votre ordinateur lorsque vous le consultez. Cela nous permet de mesurer le nombre de visites et de comprendre quelles sont les pages les plus consultées." ]
                , H.iframe
                    [ HA.class "optout"
                    , HA.src "https://stats.data.gouv.fr/index.php?module=CoreAdminHome&action=optOut&language=fr"
                    ]
                    []
                , H.h2 [] [ H.text "Ce site n'affiche pas de bannière de consentement aux cookies, pourquoi ?" ]
                , H.p [] [ H.text "Nous respectons simplement la loi, qui dit que certains outils de suivi d'audience, correctement configurés pour respecter la vie privée, sont exemptés d'autorisation préalable." ]
                , H.p []
                    [ H.text "Nous utilisons pour cela "
                    , H.a [ HA.href "https://matomo.org/" ] [ H.text "Matomo" ]
                    , H.text " un outil libre, paramétré pour être en conformité avec la "
                    , H.a [ HA.href "https://www.cnil.fr/fr/solutions-pour-la-mesure-daudience" ] [ H.text "recommandation « Cookies »" ]
                    , H.text " de la "
                    , H.abbr [ HA.title "Commission Nationale de l'Informatique et des Libertés" ] [ H.text "CNIL" ]
                    , H.text ". Cela signifie que votre adresse IP, par exemple, est anonymisée avant d'être enregistrée. Il est donc impossible d'associer vos visites sur ce site à votre personne."
                    ]
                , H.h2 [] [ H.text "Je contribue à enrichir vos données, puis-je y accéder ?" ]
                , H.p []
                    [ H.text "Bien sûr ! Les statistiques d’usage sont disponibles en accès libre sur "
                    , H.a [ HA.href "https://stats.data.gouv.fr/index.php?idSite=174" ] [ H.text "stats.data.gouv.fr" ]
                    , H.text "."
                    ]
                ]
            ]
        ]
    }

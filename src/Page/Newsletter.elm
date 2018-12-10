module Page.Newsletter exposing (Model, Msg(..), init, update, view)

import Data.Kinto exposing (Contact, KintoData(..), emptyContact)
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Kinto
import Page.Utils
import Random
import Random.Char
import Random.String
import Request.KintoContact
import Route
import Page.Utils


type alias Model =
    { contact : Contact
    , newContactKintoData : KintoData Contact
    }


type RandomPassword
    = RandomPassword String


type Msg
    = UpdateContactForm Contact
    | GenerateRandomPassword
    | SubmitNewContact RandomPassword
    | NewContactSubmitted (Result Kinto.Error Contact)
    | DiscardNotification


init : Session -> ( Model, Cmd Msg )
init session =
    ( { contact = emptyContact
      , newContactKintoData = NotRequested
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        UpdateContactForm contact ->
            ( { model | contact = contact }, Cmd.none )

        GenerateRandomPassword ->
            ( model, generateRandomPassword )

        SubmitNewContact (RandomPassword randomString) ->
            ( { model | newContactKintoData = Requested }
            , Request.KintoContact.submitContact model.contact randomString NewContactSubmitted
            )

        NewContactSubmitted (Ok contact) ->
            ( { model | newContactKintoData = Received contact, contact = emptyContact }
            , Cmd.none
            )

        NewContactSubmitted (Err error) ->
            ( { model | newContactKintoData = Failed error }
            , Cmd.none
            )

        DiscardNotification ->
            ( { model | newContactKintoData = NotRequested }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view _ { contact, newContactKintoData } =
    let
        buttonState =
            if contact.name == "" || contact.email == "" || contact.role == "" then
                Page.Utils.Disabled

            else
                case newContactKintoData of
                    Requested ->
                        Page.Utils.Loading

                    _ ->
                        Page.Utils.NotLoading
    in
    ( "Inscrivez-vous à notre infolettre"
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src "/logo_ca12.png", HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "Inscrivez-vous à notre infolettre" ]
                , H.p [] [ H.text "Tenez-vous au courant des nouvelles vidéos et de l'actualité du projet !" ]
                ]
            ]
      , H.div [ HA.class "main" ]
            [ H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ displayKintoData newContactKintoData
                    , H.form [ HE.onSubmit GenerateRandomPassword ]
                        [ formInput
                            "nom"
                            "text"
                            "Nom*"
                            "Votre nom"
                            contact.name
                            (\name -> UpdateContactForm { contact | name = name })
                        , formInput
                            "email"
                            "email"
                            "Email*"
                            "Votre adresse email"
                            contact.email
                            (\email -> UpdateContactForm { contact | email = email })
                        , H.div
                            [ HA.class "form__group" ]
                            [ H.label [ HA.for "role" ]
                                [ H.text "Role*" ]
                            , H.select
                                [ HA.id "role"
                                , HA.value contact.role
                                , Page.Utils.onChange
                                    (\role ->
                                        UpdateContactForm { contact | role = role }
                                    )
                                ]
                                [ H.option [] []
                                , H.option [ HA.value "CP" ] [ H.text "Enseignant en CP" ]
                                , H.option [ HA.value "CE1" ] [ H.text "Enseignant en CE1" ]
                                , H.option [ HA.value "Formateur" ] [ H.text "Formateur" ]
                                ]
                            ]
                        , Page.Utils.submitButton "M'inscrire à l'infolettre" buttonState
                        , H.p []
                            [ H.text "En renseignant votre nom et votre adresse email, vous acceptez de recevoir des informations ponctuelles par courrier électronique et vous prenez connaissance de notre "
                            , H.a [ Route.href Route.PrivacyPolicy ] [ H.text "politique de confidentialité" ]
                            , H.text "."
                            ]
                        , H.p []
                            [ H.text "Vous pouvez vous désinscrire à tout moment en nous contactant à l'adresse "
                            , H.a [ HA.href "mailto:contact@classea12.beta.gouv.fr?subject=désinscription infolettre" ] [ H.text "contact@classea12.beta.gouv.fr" ]
                            , H.text "."
                            ]
                        ]
                    ]
                ]
            ]
      ]
    )


formInput : String -> String -> String -> String -> String -> (String -> msg) -> H.Html msg
formInput id type_ label placeholder value onInput =
    H.div
        [ HA.class "form__group" ]
        [ H.label [ HA.for id ]
            [ H.text label ]
        , H.input
            [ HA.id id
            , HA.type_ type_
            , HA.placeholder placeholder
            , HA.value value
            , HE.onInput onInput
            ]
            []
        ]


displayKintoData : KintoData Contact -> H.Html Msg
displayKintoData kintoData =
    case kintoData of
        Failed error ->
            Page.Utils.errorNotification [ H.text (Kinto.errorToString error) ] DiscardNotification

        Received _ ->
            Page.Utils.successNotification
                [ H.text "Vous êtes maintenant inscrit à l'infolettre ! "
                , H.a [ Route.href Route.Home ] [ H.text "Retourner à la liste de vidéos" ]
                ]
                DiscardNotification

        _ ->
            H.div [] []


generateRandomPassword : Cmd Msg
generateRandomPassword =
    Random.generate
        SubmitNewContact
        (Random.String.string 20 Random.Char.latin
            |> Random.map RandomPassword
        )

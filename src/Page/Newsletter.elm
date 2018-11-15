module Page.Newsletter exposing (Model, Msg(..), init, update, view)

import Data.Kinto exposing (Contact, KintoData(..), emptyContact)
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode
import Kinto
import Random
import Random.Char
import Random.String
import Request.KintoContact
import Route


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
    ( "Inscrivez-vous à notre infolettre"
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.h1 [ HA.class "hero__white-background" ]
                    [ H.text "Inscrivez-vous à notre infolettre" ]
                , H.p [ HA.class "hero__white-background" ]
                    [ H.text "Tenez-vous au courant des nouvelles vidéos et de l'actualité du projet !" ]
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
                                , onChange
                                    (\role ->
                                        UpdateContactForm { contact | role = role }
                                    )
                                ]
                                [
                                    H.option [] []
                                    , H.option [HA.value "CP"] [H.text "Enseignant en CP"]
                                    , H.option [HA.value "CE1"] [H.text "Enseignant en CE1"]
                                    , H.option [HA.value "Formateur"] [H.text "Formateur"]
                                ]
                            ]
                        , H.button
                            [ HA.type_ "submit"
                            , HA.class "button"
                            , HA.disabled
                                (contact.name == "" || contact.email == "" || contact.role == "" || newContactKintoData == Requested)
                            ]
                            [ if newContactKintoData == Requested then
                                H.i [ HA.class "fa fa-spinner fa-spin" ] []

                              else
                                H.text " M'inscrire à l'infolettre"
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
            H.div [ HA.class "notification error closable" ]
                [ H.button
                    [ HA.class "close"
                    , HE.onClick DiscardNotification
                    ]
                    [ H.i [ HA.class "fa fa-times" ] [] ]
                , H.text <| Kinto.errorToString error
                ]

        Received _ ->
            H.div [ HA.class "notification success closable" ]
                [ H.button
                    [ HA.class "close"
                    , HE.onClick DiscardNotification
                    ]
                    [ H.i [ HA.class "fa fa-times" ] [] ]
                , H.text "Vous êtes maintenant inscrit à l'infolettre ! "
                , H.a [ Route.href Route.Home ] [ H.text "Retourner à la liste de vidéos" ]
                ]

        _ ->
            H.div [] []


generateRandomPassword : Cmd Msg
generateRandomPassword =
    Random.generate
        SubmitNewContact
        (Random.String.string 20 Random.Char.latin
            |> Random.map RandomPassword
        )


onChange : (String -> Msg) -> H.Attribute Msg
onChange tagger =
    HE.on "change" (Decode.map tagger HE.targetValue)

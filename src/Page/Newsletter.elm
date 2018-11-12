module Page.Newsletter exposing (Model, Msg(..), init, update, view)

import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE


type alias Form =
    { name : String
    , email : String
    }


emptyForm : Form
emptyForm =
    { name = "", email = "" }


type alias Model =
    { form : Form
    }


type Msg
    = UpdateNewsletterForm Form
    | SubmitNewContact


init : Session -> ( Model, Cmd Msg )
init session =
    ( { form = emptyForm }, Cmd.none )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        UpdateNewsletterForm form ->
            ( { model | form = form }, Cmd.none )

        SubmitNewContact ->
            ( model, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view _ { form } =
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
                    [ H.form [ HE.onSubmit SubmitNewContact ]
                        [ formInput
                            "nom"
                            "text"
                            "Nom*"
                            "Votre nom"
                            form.name
                            (\name -> UpdateNewsletterForm { form | name = name })
                        , formInput
                            "email"
                            "email"
                            "Email*"
                            "Votre adresse email"
                            form.email
                            (\email -> UpdateNewsletterForm { form | email = email })
                        , H.button
                            [ HA.type_ "submit"
                            , HA.class "button"
                            , HA.disabled (form.name == "" || form.email == "")
                            ]
                            [ H.text "M'inscrire à l'infolettre" ]
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

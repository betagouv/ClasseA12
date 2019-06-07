module Page.Register exposing (Model, Msg(..), init, update, view)

import Data.PeerTube
import Data.Session exposing (Session)
import Dict
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Page.Common.Components
import Page.Common.Notifications as Notifications
import Request.PeerTube
import Route


type alias Model =
    { title : String
    , registerForm : RegisterForm
    , notifications : Notifications.Model
    , registration : Data.PeerTube.RemoteData String
    , approved : Bool
    , formErrors : Dict.Dict String (List String)
    }


type alias RegisterForm =
    { username : String
    , email : String
    , password : String
    }


emptyRegisterForm : RegisterForm
emptyRegisterForm =
    { username = "", email = "", password = "" }


type Msg
    = UpdateRegisterForm RegisterForm
    | Register
    | NotificationMsg Notifications.Msg
    | AccountRegistered (Result Http.Error String)
    | OnApproved Bool
    | OnBlur String String


init : Session -> ( Model, Cmd Msg )
init _ =
    ( { title = "Inscription"
      , registerForm = emptyRegisterForm
      , notifications = Notifications.init
      , registration = Data.PeerTube.NotRequested
      , approved = False
      , formErrors = Dict.empty
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        UpdateRegisterForm registerForm ->
            ( { model | registerForm = registerForm }, Cmd.none )

        Register ->
            registerAccount session.peerTubeURL model

        AccountRegistered (Ok _) ->
            ( { model | registration = Data.PeerTube.Received "Votre compte a été créé ! Il vous reste à l'activer : un mail vient de vous être envoyé avec un code d'activation. " }
            , Cmd.none
            )

        AccountRegistered (Err error) ->
            let
                errorMessage =
                    case error of
                        Http.BadStatus response ->
                            case response.status.code of
                                400 ->
                                    "Inscription échouée : le nom d'utilisateur ou l'email ne sont pas valides"

                                409 ->
                                    "Inscription échouée : un utilisateur avec le même nom ou email existe déjà"

                                _ ->
                                    "Inscription échouée"

                        _ ->
                            "Inscription échouée"
            in
            ( { model
                | notifications =
                    errorMessage
                        |> Notifications.addError model.notifications
                , registration = Data.PeerTube.NotRequested
              }
            , Cmd.none
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }, Cmd.none )

        OnApproved approved ->
            ( { model | approved = approved }, Cmd.none )

        OnBlur fieldName fieldValue ->
            ( { model
                | formErrors =
                    model.formErrors
                        |> Dict.insert fieldName (validateField fieldName fieldValue)
              }
            , Cmd.none
            )


validateField : String -> String -> List String
validateField fieldName fieldValue =
    case fieldName of
        "username" ->
            if isUsernameValid fieldValue then
                []

            else
                [ "Uniquement des caractères alphanumériques sans espace" ]

        "email" ->
            if isEmailValid fieldValue then
                []

            else
                [ "L'adresse email doit terminer par un nom de domaine académique comme @ac-creteil.fr" ]

        "password" ->
            if String.length fieldValue < 6 then
                [ "Le mot de passe doit faire au minimum 6 caractères" ]

            else
                []

        _ ->
            []


isUsernameValid : String -> Bool
isUsernameValid username =
    username /= "" && String.all Char.isAlphaNum username


isRegisterFormComplete : RegisterForm -> Bool -> Bool
isRegisterFormComplete registerForm approved =
    approved
        && (registerForm.username /= "")
        && (registerForm.email /= "")
        && (registerForm.password /= "")
        && (String.length registerForm.password >= 6)
        && isEmailValid registerForm.email


isEmailValid : String -> Bool
isEmailValid email =
    let
        validDomains =
            [ "ac-lille.fr"
            , "ac-rouen.fr"
            , "ac-amiens.fr"
            , "ac-caen.fr"
            , "ac-versailles.fr"
            , "ac-paris.fr"
            , "ac-creteil.fr"
            , "ac-reims.fr"
            , "ac-nancy-metz.fr"
            , "ac-strasbourg.fr"
            , "ac-rennes.fr"
            , "ac-nantes.fr"
            , "ac-orleans-tours.fr"
            , "ac-dijon.fr"
            , "ac-besancon.fr"
            , "ac-poitiers.fr"
            , "ac-limoges.fr"
            , "ac-clermont.fr"
            , "ac-lyon.fr"
            , "ac-grenoble.fr"
            , "ac-bordeaux.fr"
            , "ac-toulouse.fr"
            , "ac-montpellier.fr"
            , "ac-aix-marseille.fr"
            , "ac-nice.fr"
            , "ac-corse.fr"
            , "ac-martinique.fr"
            , "ac-guadeloupe.fr"
            , "ac-reunion.fr"
            , "ac-guyane.fr"
            , "ac-mayotte.fr"
            , "ac-noumea.nc"
            , "ac-wf.wf"
            , "ac-spm.fr"
            , "ac-polynesie.pf"
            ]

        normalizedEmail =
            String.toLower email
    in
    validDomains
        |> List.filter (\domain -> String.endsWith ("@" ++ domain) normalizedEmail)
        |> List.length
        |> (==) 1


registerAccount : String -> Model -> ( Model, Cmd Msg )
registerAccount peerTubeURL model =
    if isRegisterFormComplete model.registerForm model.approved then
        ( { model | registration = Data.PeerTube.Requested }
        , Request.PeerTube.register model.registerForm.username model.registerForm.email model.registerForm.password peerTubeURL AccountRegistered
        )

    else
        ( model, Cmd.none )


view : Session -> Model -> Page.Common.Components.Document Msg
view _ { title, notifications, registerForm, registration, approved, formErrors } =
    { title = title
    , pageTitle = title
    , pageSubTitle = ""
    , body =
        [ H.map NotificationMsg (Notifications.view notifications)
        , H.div [ HA.class "section " ]
            [ H.div [ HA.class "container" ]
                [ case registration of
                    Data.PeerTube.Received message ->
                        H.div []
                            [ H.text message
                            ]

                    _ ->
                        viewRegisterForm registerForm registration approved formErrors
                ]
            ]
        ]
    }


viewRegisterForm : RegisterForm -> Data.PeerTube.RemoteData String -> Bool -> Dict.Dict String (List String) -> H.Html Msg
viewRegisterForm registerForm registration approved formErrors =
    let
        formComplete =
            isRegisterFormComplete registerForm approved

        buttonState =
            if formComplete then
                case registration of
                    Data.PeerTube.Requested ->
                        Page.Common.Components.Loading

                    _ ->
                        Page.Common.Components.NotLoading

            else
                Page.Common.Components.Disabled

        submitButton =
            Page.Common.Components.submitButton "Créer ce compte" buttonState
    in
    H.form
        [ HE.onSubmit Register ]
        [ H.h1 [] [ H.text "Formulaire de création de compte" ]
        , H.p []
            [ H.text "L'utilisation de ce service est régi par une "
            , H.a
                [ Route.href Route.Convention ]
                [ H.text "charte de bonne conduite" ]
            , H.text " et des "
            , H.a
                [ Route.href Route.CGU ]
                [ H.text "conditions générales d'utilisation" ]
            , H.text "."
            ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "username" ] [ H.text "Nom d'utilisateur (uniquement des caractères alphanumériques sans espace)" ]
            , H.input
                [ HA.type_ "text"
                , HA.id "username"
                , HA.value registerForm.username
                , HA.pattern "[A-Za-z0-9]+"
                , HE.onInput <| \username -> UpdateRegisterForm { registerForm | username = username }
                , HE.onBlur <| OnBlur "username" registerForm.username
                ]
                []
            , viewFormErrors "username" formErrors
            ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "email" ] [ H.text "Email (adresse académique uniquement)" ]
            , H.input
                [ HA.type_ "email"
                , HA.id "email"
                , HA.value registerForm.email
                , HE.onInput <| \email -> UpdateRegisterForm { registerForm | email = email }
                , HE.onBlur <| OnBlur "email" registerForm.email
                ]
                []
            , viewFormErrors "email" formErrors
            ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "password" ] [ H.text "Mot de passe (minimum 6 caractères)" ]
            , H.input
                [ HA.type_ "password"
                , HA.value registerForm.password
                , HA.minlength 6
                , HE.onInput <| \password -> UpdateRegisterForm { registerForm | password = password }
                , HE.onBlur <| OnBlur "password" registerForm.password
                ]
                []
            , viewFormErrors "password" formErrors
            ]
        , H.div
            [ HA.class "form__group" ]
            [ H.input
                [ HA.id "approve_CGU"
                , HA.type_ "checkbox"
                , HA.checked approved
                , HE.onCheck OnApproved
                ]
                []
            , H.label [ HA.for "approve_CGU", HA.class "label-inline" ]
                [ H.text "J'ai lu et j'accepte d'adhérer à la charte de bonne conduite" ]
            ]
        , submitButton
        ]


viewFormErrors : String -> Dict.Dict String (List String) -> H.Html Msg
viewFormErrors fieldName formErrors =
    case Dict.get fieldName formErrors of
        Just fieldErrors ->
            H.ul [ HA.class "form-errors" ]
                (fieldErrors
                    |> List.map
                        (\error ->
                            H.li []
                                [ H.img [ HA.src "%PUBLIC_URL%/images/icons/16x16/message_alert_16_red.svg" ] []
                                , H.text " "
                                , H.text error
                                ]
                        )
                )

        Nothing ->
            H.text ""

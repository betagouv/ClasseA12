module Page.Register exposing (Model, Msg(..), init, update, view)

import Data.PeerTube
import Data.Session exposing (Session)
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


init : Session -> ( Model, Cmd Msg )
init _ =
    ( { title = "Inscription"
      , registerForm = emptyRegisterForm
      , notifications = Notifications.init
      , registration = Data.PeerTube.NotRequested
      , approved = False
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
    in
    validDomains
        |> List.filter (\domain -> String.endsWith ("@" ++ domain) email)
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
view _ { title, notifications, registerForm, registration, approved } =
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
                        viewRegisterForm registerForm registration approved
                ]
            ]
        ]
    }


viewRegisterForm : RegisterForm -> Data.PeerTube.RemoteData String -> Bool -> H.Html Msg
viewRegisterForm registerForm registration approved =
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
                , HE.onInput <| \username -> UpdateRegisterForm { registerForm | username = username }
                ]
                []
            ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "email" ] [ H.text "Email (adresse académique uniquement)" ]
            , H.input
                [ HA.type_ "email"
                , HA.id "email"
                , HA.value registerForm.email
                , HE.onInput <| \email -> UpdateRegisterForm { registerForm | email = email }
                ]
                []
            ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "password" ] [ H.text "Mot de passe (minimum 6 caractères)" ]
            , H.input
                [ HA.type_ "password"
                , HA.value registerForm.password
                , HE.onInput <| \password -> UpdateRegisterForm { registerForm | password = password }
                ]
                []
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

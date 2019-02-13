module Page.Register exposing (Model, Msg(..), init, update, view)

import Data.Kinto
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Kinto
import Page.Utils
import Ports
import Request.Kinto exposing (authClient)
import Request.KintoAccount
import Route


type alias Model =
    { registerForm : RegisterForm
    , error : Maybe String
    , userInfoData : Data.Kinto.KintoData Request.KintoAccount.UserInfo
    }


type alias RegisterForm =
    { email : String
    , password : String
    , password2 : String
    }


emptyRegisterForm : RegisterForm
emptyRegisterForm =
    { email = "", password = "", password2 = "" }


type Msg
    = UpdateRegisterForm RegisterForm
    | Register
    | DiscardError
    | UserInfoReceived (Result Http.Error Request.KintoAccount.UserInfo)


init : Session -> ( Model, Cmd Msg )
init session =
    ( { registerForm = emptyRegisterForm
      , error = Nothing
      , userInfoData = Data.Kinto.NotRequested
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        UpdateRegisterForm registerForm ->
            ( { model | registerForm = registerForm }, Cmd.none )

        Register ->
            registerAccount session.kintoURL model

        DiscardError ->
            ( { model | error = Nothing }, Cmd.none )

        UserInfoReceived (Ok userInfo) ->
            ( { model | error = Nothing, userInfoData = Data.Kinto.Received userInfo }
            , Cmd.none
            )

        UserInfoReceived (Err error) ->
            let
                kintoError =
                    Kinto.extractError error
            in
            ( { model | error = Just <| "Inscription échouéeba : " ++ Kinto.errorToString kintoError, userInfoData = Data.Kinto.NotRequested }, Cmd.none )


isRegisterFormComplete : RegisterForm -> Bool
isRegisterFormComplete registerForm =
    registerForm.email /= "" && registerForm.password /= "" && registerForm.password == registerForm.password2


registerAccount : String -> Model -> ( Model, Cmd Msg )
registerAccount kintoURL model =
    if isRegisterFormComplete model.registerForm then
        ( { model | userInfoData = Data.Kinto.Requested }
        , Request.KintoAccount.register kintoURL model.registerForm.email model.registerForm.password UserInfoReceived
        )

    else
        ( model, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view _ { error, registerForm, userInfoData } =
    ( "Inscription"
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src "/logo_ca12.png", HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "Inscription" ]
                ]
            ]
      , H.div [ HA.class "main" ]
            [ viewError error
            , H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ case userInfoData of
                        Data.Kinto.Received userInfo ->
                            H.div []
                                [ H.text "Votre compte a été créé ! Il vous reste à l'activer : un mail vient de vous être envoyé avec un code d'activation. "
                                ]

                        _ ->
                            viewRegisterForm registerForm userInfoData
                    ]
                ]
            ]
      ]
    )


viewRegisterForm : RegisterForm -> Request.KintoAccount.UserInfoData -> H.Html Msg
viewRegisterForm registerForm userInfoData =
    let
        formComplete =
            isRegisterFormComplete registerForm

        buttonState =
            if formComplete then
                case userInfoData of
                    Data.Kinto.Requested ->
                        Page.Utils.Loading

                    _ ->
                        Page.Utils.NotLoading

            else
                Page.Utils.Disabled

        submitButton =
            Page.Utils.submitButton "Créer ce compte" buttonState

        passwordsDontMatch =
            registerForm.password2 /= "" && registerForm.password /= registerForm.password2
    in
    H.form
        [ HE.onSubmit Register ]
        [ H.h1 [] [ H.text "Formulaire de création de compte" ]
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
            [ H.label [ HA.for "password" ] [ H.text "Mot de passe" ]
            , H.input
                [ HA.type_ "password"
                , HA.value registerForm.password
                , HE.onInput <| \password -> UpdateRegisterForm { registerForm | password = password }
                ]
                []
            ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "password2" ] [ H.text "Confirmer le mot de passe" ]
            , H.input
                [ HA.type_ "password"
                , HA.value registerForm.password2
                , HA.class <|
                    if passwordsDontMatch then
                        "invalid"

                    else
                        ""
                , HE.onInput <| \password2 -> UpdateRegisterForm { registerForm | password2 = password2 }
                ]
                []
            ]
        , submitButton
        ]


viewError : Maybe String -> H.Html Msg
viewError maybeError =
    case maybeError of
        Just error ->
            Page.Utils.errorNotification [ H.text error ] DiscardError

        Nothing ->
            H.div [] []

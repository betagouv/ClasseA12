module Page.Profile exposing (Model, Msg(..), init, update, view)

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
import Request.KintoProfile
import Route


type alias Model =
    { profileForm : Data.Kinto.Profile
    , error : Maybe String
    , profileData : Data.Kinto.ProfileData
    , userInfoData : Data.Kinto.UserInfoData
    }


type Msg
    = UpdateProfileForm Data.Kinto.Profile
    | SubmitProfile
    | DiscardError
    | ProfileCreated (Result Kinto.Error Data.Kinto.Profile)
    | ProfileAssociated Data.Kinto.Profile (Result Http.Error Data.Kinto.UserInfo)


init : Session -> ( Model, Cmd Msg )
init session =
    let
        guessedName =
            session.userData.username
                |> String.split "@"
                |> List.head
                |> Maybe.withDefault ""

        emptyProfile =
            Data.Kinto.emptyProfile
    in
    ( { profileForm = { emptyProfile | name = guessedName }
      , error = Nothing
      , profileData = Data.Kinto.NotRequested
      , userInfoData = Data.Kinto.NotRequested
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        UpdateProfileForm profileForm ->
            ( { model | profileForm = profileForm }, Cmd.none )

        SubmitProfile ->
            submitProfile session model

        DiscardError ->
            ( { model | error = Nothing }, Cmd.none )

        ProfileCreated (Ok profile) ->
            ( { model | error = Nothing, profileData = Data.Kinto.Received profile, userInfoData = Data.Kinto.Requested }
            , Request.KintoAccount.associateProfile
                session.kintoURL
                session.userData.username
                session.userData.password
                profile.id
                (ProfileAssociated profile)
            )

        ProfileCreated (Err error) ->
            ( { model | error = Just <| "Création du profil échouée : " ++ Kinto.errorToString error, profileData = Data.Kinto.NotRequested }, Cmd.none )

        ProfileAssociated profile (Ok userInfo) ->
            ( { model
                | error = Nothing
                , userInfoData = Data.Kinto.Received userInfo
              }
            , Cmd.none
            )

        ProfileAssociated _ (Err error) ->
            let
                kintoError =
                    Kinto.extractError error
            in
            ( { model | error = Just <| "Association du profil échouée : " ++ Kinto.errorToString kintoError, userInfoData = Data.Kinto.NotRequested }, Cmd.none )


isProfileFormComplete : Data.Kinto.Profile -> Bool
isProfileFormComplete profileForm =
    profileForm.name /= ""


submitProfile : { a | kintoURL : String, userData : Data.Session.UserData } -> Model -> ( Model, Cmd Msg )
submitProfile { kintoURL, userData } model =
    if isProfileFormComplete model.profileForm && userData /= Data.Session.emptyUserData then
        let
            client =
                Request.Kinto.authClient kintoURL userData.username userData.password
        in
        ( { model | profileData = Data.Kinto.Requested }
        , Request.KintoProfile.submitProfile client model.profileForm ProfileCreated
        )

    else
        ( model, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view { userData } { error, profileForm, profileData, userInfoData } =
    ( "Création du profil"
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src "/logo_ca12.png", HA.class "hero__logo" ] []
                , H.h1 [] [ H.text <| "Création du profil" ]
                ]
            ]
      , H.div [ HA.class "main" ]
            [ viewError error
            , H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    (if userData /= Data.Session.emptyUserData then
                        [ case userInfoData of
                            Data.Kinto.Received _ ->
                                H.div []
                                    [ H.text "Votre profil a été créé ! Vous pouvez maintenant "
                                    , H.a [ Route.href Route.Home ] [ H.text "comment sur des vidéos" ]
                                    , H.text " ou "
                                    , H.a [ Route.href Route.Participate ] [ H.text "en proposer !" ]
                                    ]

                            _ ->
                                viewProfileForm profileForm profileData userInfoData
                        ]

                     else
                        [ Page.Utils.viewConnectNow "Pour accéder à cette page veuillez vous " "connecter" ]
                    )
                ]
            ]
      ]
    )


viewProfileForm : Data.Kinto.Profile -> Data.Kinto.ProfileData -> Data.Kinto.UserInfoData -> H.Html Msg
viewProfileForm profileForm profileData userInfoData =
    let
        formComplete =
            isProfileFormComplete profileForm

        buttonState =
            if formComplete then
                case profileData of
                    Data.Kinto.Requested ->
                        Page.Utils.Loading

                    Data.Kinto.Received _ ->
                        -- Profile created
                        case userInfoData of
                            Data.Kinto.Requested ->
                                Page.Utils.Loading

                            _ ->
                                Page.Utils.NotLoading

                    _ ->
                        Page.Utils.NotLoading

            else
                Page.Utils.Disabled

        submitButton =
            Page.Utils.submitButton "Créer mon profil" buttonState
    in
    H.form
        [ HE.onSubmit SubmitProfile ]
        [ H.h1 [] [ H.text "Formulaire de création de profil" ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "name" ] [ H.text "Nom d'usage (utilisé comme identité sur ce site)" ]
            , H.input
                [ HA.type_ "text"
                , HA.id "name"
                , HA.value profileForm.name
                , HE.onInput <| \name -> UpdateProfileForm { profileForm | name = name }
                ]
                []
            ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "bio" ] [ H.text "Bio (description facultative)" ]
            , H.textarea
                [ HE.onInput <| \bio -> UpdateProfileForm { profileForm | bio = bio }
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

module Page.Profile exposing (Model, Msg(..), init, update, view)

import Data.Kinto
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Kinto
import Markdown
import Page.Common.Components
import Page.Common.Notifications as Notifications
import Ports
import Request.Kinto exposing (authClient)
import Request.KintoAccount
import Request.KintoProfile
import Route


type alias Model =
    { pageState : PageState
    , profileForm : Data.Kinto.Profile
    , profileData : Data.Kinto.ProfileData
    , userInfoData : Data.Kinto.UserInfoData
    , notifications : Notifications.Model
    }


type PageState
    = CreateProfile
    | GetProfile
    | ViewProfile Data.Kinto.Profile
    | EditProfile Data.Kinto.Profile


type Msg
    = UpdateProfileForm Data.Kinto.Profile
    | SubmitProfile
    | UpdateProfile
    | NotificationMsg Notifications.Msg
    | ProfileFetchedForEdit (Result Kinto.Error Data.Kinto.Profile)
    | ProfileFetchedForView (Result Kinto.Error Data.Kinto.Profile)
    | ProfileCreated (Result Kinto.Error Data.Kinto.Profile)
    | ProfileAssociated Data.Kinto.Profile (Result Http.Error Data.Kinto.UserInfo)
    | ProfileUpdated (Result Kinto.Error Data.Kinto.Profile)
    | Logout


init : Maybe String -> Session -> ( Model, Cmd Msg )
init maybeProfile session =
    case maybeProfile of
        Just profile ->
            let
                msg =
                    if profile == Maybe.withDefault "no user profile" session.userData.profile then
                        -- Profile edition
                        ProfileFetchedForEdit

                    else
                        -- View profile from other user
                        ProfileFetchedForView
            in
            ( { pageState = GetProfile
              , profileForm = Data.Kinto.emptyProfile
              , profileData = Data.Kinto.NotRequested
              , userInfoData = Data.Kinto.NotRequested
              , notifications = Notifications.init
              }
            , Request.KintoProfile.getProfile session.kintoURL profile msg
            )

        Nothing ->
            -- Profile creation
            let
                guessedName =
                    session.userData.username
                        |> String.split "@"
                        |> List.head
                        |> Maybe.withDefault ""

                emptyProfile =
                    Data.Kinto.emptyProfile
            in
            ( { pageState = CreateProfile
              , profileForm = { emptyProfile | name = guessedName }
              , profileData = Data.Kinto.NotRequested
              , userInfoData = Data.Kinto.NotRequested
              , notifications = Notifications.init
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

        UpdateProfile ->
            updateProfile session model

        ProfileFetchedForEdit (Ok profile) ->
            let
                profileForm =
                    model.profileForm

                updatedProfileForm =
                    { profileForm | name = profile.name, bio = profile.bio, id = profile.id }
            in
            ( { model
                | profileData = Data.Kinto.Received profile
                , profileForm = updatedProfileForm
                , pageState = EditProfile profile
              }
            , Cmd.none
            )

        ProfileFetchedForEdit (Err error) ->
            ( { model
                | notifications =
                    "Récupération du profil échouée : "
                        ++ Kinto.errorToString error
                        |> Notifications.addError model.notifications
                , profileData = Data.Kinto.NotRequested
              }
            , Cmd.none
            )

        ProfileFetchedForView (Ok profile) ->
            ( { model
                | profileData = Data.Kinto.Received profile
                , pageState = ViewProfile profile
              }
            , Cmd.none
            )

        ProfileFetchedForView (Err error) ->
            ( { model
                | notifications =
                    "Récupération du profil échouée : "
                        ++ Kinto.errorToString error
                        |> Notifications.addError model.notifications
                , profileData = Data.Kinto.NotRequested
              }
            , Cmd.none
            )

        ProfileCreated (Ok profile) ->
            ( { model | profileData = Data.Kinto.Received profile, userInfoData = Data.Kinto.Requested }
            , Request.KintoAccount.associateProfile
                session.kintoURL
                session.userData.username
                session.userData.password
                profile.id
                (ProfileAssociated profile)
            )

        ProfileCreated (Err error) ->
            ( { model
                | notifications =
                    "Création du profil échouée : "
                        ++ Kinto.errorToString error
                        |> Notifications.addError model.notifications
                , profileData = Data.Kinto.NotRequested
              }
            , Cmd.none
            )

        ProfileAssociated profile (Ok userInfo) ->
            ( { model
                | userInfoData = Data.Kinto.Received userInfo
              }
            , Cmd.none
            )

        ProfileAssociated _ (Err error) ->
            let
                kintoError =
                    Kinto.extractError error
            in
            ( { model
                | notifications =
                    "Association du profil échouée : "
                        ++ Kinto.errorToString kintoError
                        |> Notifications.addError model.notifications
                , userInfoData = Data.Kinto.NotRequested
              }
            , Cmd.none
            )

        ProfileUpdated (Ok profile) ->
            ( { model
                | notifications =
                    "Profil mis à jour !"
                        |> Notifications.addSuccess model.notifications
                , profileData = Data.Kinto.Received profile
              }
            , Cmd.none
            )

        ProfileUpdated (Err error) ->
            ( { model
                | notifications =
                    "Mise à jour du profil échouée : "
                        ++ Kinto.errorToString error
                        |> Notifications.addError model.notifications
                , profileData = Data.Kinto.NotRequested
              }
            , Cmd.none
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }, Cmd.none )

        Logout ->
            -- This message is dealt with in the `Main` module.
            ( model, Cmd.none )


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


updateProfile : { a | kintoURL : String, userData : Data.Session.UserData } -> Model -> ( Model, Cmd Msg )
updateProfile { kintoURL, userData } model =
    if isProfileFormComplete model.profileForm && userData /= Data.Session.emptyUserData then
        let
            client =
                Request.Kinto.authClient kintoURL userData.username userData.password
        in
        ( { model | profileData = Data.Kinto.Requested }
        , Request.KintoProfile.updateProfile client model.profileForm ProfileUpdated
        )

    else
        ( model, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view { staticFiles, userData } { pageState, profileForm, profileData, userInfoData, notifications } =
    let
        title =
            case pageState of
                CreateProfile ->
                    "Création du profil"

                EditProfile _ ->
                    "Édition du profil"

                _ ->
                    "Profil"
    in
    ( title
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src staticFiles.logo_ca12, HA.class "hero__logo" ] []
                , H.h1 [] [ H.text title ]
                ]
            ]
      , H.div [ HA.class "main" ]
            [ H.map NotificationMsg (Notifications.view notifications)
            , H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ case pageState of
                        GetProfile ->
                            H.div [] [ H.text "Un instant, récupération du profil..." ]

                        ViewProfile profile ->
                            viewProfile profile

                        EditProfile profile ->
                            viewEditProfileForm pageState profileForm profileData userInfoData

                        CreateProfile ->
                            if userData /= Data.Session.emptyUserData then
                                -- User is logged in, and creating their profile
                                case userInfoData of
                                    Data.Kinto.Received _ ->
                                        H.div []
                                            [ H.text "Votre profil a été créé ! Vous pouvez maintenant "
                                            , H.a [ Route.href Route.Home ] [ H.text "commenter sur des vidéos" ]
                                            , H.text " ou "
                                            , H.a [ Route.href Route.Participate ] [ H.text "en proposer !" ]
                                            ]

                                    _ ->
                                        viewCreateProfileForm pageState profileForm profileData userInfoData

                            else
                                -- User not logged in
                                Page.Common.Components.viewConnectNow "Pour accéder à cette page veuillez vous " "connecter"
                    ]
                ]
            ]
      ]
    )


viewProfile : Data.Kinto.Profile -> H.Html Msg
viewProfile profileData =
    H.div []
        [ H.h3 [] [ H.text <| "Profil de " ++ profileData.name ]
        , Markdown.toHtml [] profileData.bio
        ]


viewProfileForm : H.Html Msg -> Msg -> Data.Kinto.Profile -> H.Html Msg
viewProfileForm submitButton msg profileForm =
    H.form
        [ HE.onSubmit msg ]
        [ H.div [ HA.class "form__group" ]
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
                [ HA.value profileForm.bio
                , HE.onInput <| \bio -> UpdateProfileForm { profileForm | bio = bio }
                ]
                []
            ]
        , submitButton
        ]


viewCreateProfileForm : PageState -> Data.Kinto.Profile -> Data.Kinto.ProfileData -> Data.Kinto.UserInfoData -> H.Html Msg
viewCreateProfileForm pageState profileForm profileData userInfoData =
    let
        formComplete =
            isProfileFormComplete profileForm

        buttonState =
            if formComplete then
                case profileData of
                    Data.Kinto.Requested ->
                        Page.Common.Components.Loading

                    Data.Kinto.Received _ ->
                        -- Profile created
                        case userInfoData of
                            Data.Kinto.Requested ->
                                Page.Common.Components.Loading

                            _ ->
                                Page.Common.Components.NotLoading

                    _ ->
                        Page.Common.Components.NotLoading

            else
                Page.Common.Components.Disabled

        submitButton =
            Page.Common.Components.submitButton "Créer mon profil" buttonState
    in
    viewProfileForm submitButton SubmitProfile profileForm


viewEditProfileForm : PageState -> Data.Kinto.Profile -> Data.Kinto.ProfileData -> Data.Kinto.UserInfoData -> H.Html Msg
viewEditProfileForm pageState profileForm profileData userInfoData =
    let
        formComplete =
            isProfileFormComplete profileForm

        buttonState =
            if formComplete then
                case profileData of
                    Data.Kinto.Requested ->
                        Page.Common.Components.Loading

                    _ ->
                        Page.Common.Components.NotLoading

            else
                Page.Common.Components.Disabled

        submitButton =
            H.div []
                [ Page.Common.Components.submitButton "Mettre à jour mon profil" buttonState
                , H.button [ HA.class "button warning", HE.onClick Logout ] [ H.text "Me déconnecter" ]
                ]
    in
    viewProfileForm submitButton UpdateProfile profileForm

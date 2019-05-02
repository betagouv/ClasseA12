module Page.Profile exposing (Model, Msg(..), init, update, view)

import Data.PeerTube
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Kinto
import Markdown
import Page.Common.Components
import Page.Common.Notifications as Notifications
import Request.PeerTube


type alias Model =
    { title : String
    , pageState : PageState
    , profileForm : ProfileForm
    , profileData : Data.PeerTube.RemoteData Data.PeerTube.Account
    , ownProfile : Bool
    , notifications : Notifications.Model
    }


type alias ProfileForm =
    { displayName : String
    , description : String
    }


emptyProfileForm =
    { displayName = ""
    , description = ""
    }


type PageState
    = GetProfile
    | ViewProfile Data.PeerTube.Account
    | EditProfile Data.PeerTube.Account


type Msg
    = UpdateProfileForm ProfileForm
    | UpdateProfile
    | NotificationMsg Notifications.Msg
    | ProfileFetchedForEdit (Result Http.Error Data.PeerTube.Account)
    | ProfileFetchedForView (Result Http.Error Data.PeerTube.Account)
    | ProfileUpdated (Result Http.Error Data.PeerTube.Account)
    | Logout


init : String -> Session -> ( Model, Cmd Msg )
init profile session =
    let
        ownProfile =
            session.userInfo
                |> Maybe.map (\userInfo -> userInfo.username == profile)
                |> Maybe.withDefault False

        ( msg, title ) =
            if ownProfile then
                -- Profile edition
                ( ProfileFetchedForEdit, "Édition du profil" )

            else
                ( ProfileFetchedForView, "Profil" )
    in
    ( { title = title
      , pageState = GetProfile
      , profileForm = emptyProfileForm
      , profileData = Data.PeerTube.NotRequested
      , ownProfile = ownProfile
      , notifications = Notifications.init
      }
    , Request.PeerTube.getAccount profile session.peerTubeURL msg
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg, Maybe Data.Session.Msg )
update session msg model =
    case msg of
        UpdateProfileForm profileForm ->
            ( { model | profileForm = profileForm }
            , Cmd.none
            , Nothing
            )

        UpdateProfile ->
            updateProfile session model

        ProfileFetchedForEdit (Ok profile) ->
            let
                profileForm =
                    model.profileForm

                updatedProfileForm =
                    { profileForm
                        | displayName = profile.displayName
                        , description = profile.description
                    }
            in
            ( { model
                | profileData = Data.PeerTube.Received profile
                , profileForm = updatedProfileForm
                , pageState = EditProfile profile
              }
            , Cmd.none
            , Nothing
            )

        ProfileFetchedForEdit (Err error) ->
            ( { model
                | notifications =
                    "Récupération du profil échouée"
                        |> Notifications.addError model.notifications
                , profileData = Data.PeerTube.NotRequested
              }
            , Cmd.none
            , Data.Session.logoutIf401 error
            )

        ProfileFetchedForView (Ok profile) ->
            ( { model
                | profileData = Data.PeerTube.Received profile
                , pageState = ViewProfile profile
              }
            , Cmd.none
            , Nothing
            )

        ProfileFetchedForView (Err error) ->
            ( { model
                | notifications =
                    "Récupération du profil échouée"
                        |> Notifications.addError model.notifications
                , profileData = Data.PeerTube.NotRequested
              }
            , Cmd.none
            , Nothing
            )

        ProfileUpdated (Ok profile) ->
            ( { model
                | notifications =
                    "Profil mis à jour !"
                        |> Notifications.addSuccess model.notifications
                , profileData = Data.PeerTube.Received profile
              }
            , Cmd.none
            , Nothing
            )

        ProfileUpdated (Err error) ->
            ( { model
                | notifications =
                    "Mise à jour du profil échouée"
                        |> Notifications.addError model.notifications
                , profileData = Data.PeerTube.NotRequested
              }
            , Cmd.none
            , Data.Session.logoutIf401 error
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }
            , Cmd.none
            , Nothing
            )

        Logout ->
            ( model, Cmd.none, Just Data.Session.Logout )


isProfileFormComplete : ProfileForm -> Bool
isProfileFormComplete profileForm =
    profileForm.displayName /= ""


updateProfile :
    { a | peerTubeURL : String, userInfo : Maybe Data.PeerTube.UserInfo, userToken : Maybe Data.PeerTube.UserToken }
    -> Model
    -> ( Model, Cmd Msg, Maybe Data.Session.Msg )
updateProfile { peerTubeURL, userInfo, userToken } model =
    if isProfileFormComplete model.profileForm && Data.Session.isPeerTubeLoggedIn userInfo then
        case userToken of
            Just { access_token } ->
                ( { model | profileData = Data.PeerTube.Requested }
                , Request.PeerTube.updateUserAccount
                    model.profileForm.displayName
                    model.profileForm.description
                    access_token
                    peerTubeURL
                    ProfileUpdated
                , Nothing
                )

            Nothing ->
                ( model, Cmd.none, Nothing )

    else
        ( model, Cmd.none, Nothing )


view : Session -> Model -> Page.Common.Components.Document Msg
view { staticFiles } { title, pageState, profileForm, profileData, ownProfile, notifications } =
    let
        logoutButton =
            if ownProfile then
                [ H.button [ HA.class "button warning", HE.onClick Logout ] [ H.text "Me déconnecter" ] ]

            else
                []
    in
    { title = title
    , pageTitle = title
    , pageSubTitle = ""
    , body =
        [ H.map NotificationMsg (Notifications.view notifications)
        , H.div [ HA.class "section section-white" ]
            [ H.div [ HA.class "container" ]
                [ case pageState of
                    GetProfile ->
                        H.div [] [ H.text "Un instant, récupération du profil..." ]

                    ViewProfile profile ->
                        viewProfile profile

                    EditProfile profile ->
                        viewEditProfileForm pageState profileForm profileData
                ]
            ]
        ]
            ++ logoutButton
    }


viewProfile : Data.PeerTube.Account -> H.Html Msg
viewProfile profileData =
    H.div []
        [ H.h3 [] [ H.text <| "Profil de " ++ profileData.displayName ]
        , Markdown.toHtml [] profileData.description
        ]


viewEditProfileForm : PageState -> ProfileForm -> Data.PeerTube.RemoteData Data.PeerTube.Account -> H.Html Msg
viewEditProfileForm pageState profileForm profileData =
    let
        formComplete =
            isProfileFormComplete profileForm

        buttonState =
            if formComplete then
                case profileData of
                    Data.PeerTube.Requested ->
                        Page.Common.Components.Loading

                    _ ->
                        Page.Common.Components.NotLoading

            else
                Page.Common.Components.Disabled

        submitButton =
            H.div []
                [ Page.Common.Components.submitButton "Mettre à jour mon profil" buttonState ]
    in
    H.form
        [ HE.onSubmit UpdateProfile ]
        [ H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "name" ] [ H.text "Nom d'usage (utilisé comme identité sur ce site)" ]
            , H.input
                [ HA.type_ "text"
                , HA.id "name"
                , HA.value profileForm.displayName
                , HE.onInput <| \displayName -> UpdateProfileForm { profileForm | displayName = displayName }
                ]
                []
            ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "bio" ] [ H.text "Bio (description facultative)" ]
            , H.textarea
                [ HA.value profileForm.description
                , HE.onInput <| \description -> UpdateProfileForm { profileForm | description = description }
                ]
                []
            ]
        , submitButton
        ]

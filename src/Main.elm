port module Main exposing (main)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Data.Kinto
import Data.Session exposing (Session, decodeStaticFiles, decodeUserData, emptyStaticFiles, emptyUserData, encodeUserData)
import Dict
import Html exposing (..)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Kinto
import Page.About as About
import Page.Activate as Activate
import Page.Admin as Admin
import Page.CGU as CGU
import Page.Comments as Comments
import Page.Convention as Convention
import Page.Home as Home
import Page.Login as Login
import Page.Newsletter as Newsletter
import Page.Participate as Participate
import Page.PeerTube as PeerTube
import Page.PeerTubeAccount as PeerTubeAccount
import Page.PeerTubeVideo as PeerTubeVideo
import Page.PrivacyPolicy as PrivacyPolicy
import Page.Profile as Profile
import Page.Register as Register
import Page.ResetPassword as ResetPassword
import Page.SetNewPassword as SetNewPassword
import Page.Video as Video
import Platform.Sub
import Ports
import Route exposing (Route)
import Task
import Time
import Url exposing (Url)
import Views.Page as Page


type alias Flags =
    Encode.Value


type Page
    = HomePage Home.Model
    | PeerTubePage PeerTube.Model
    | PeerTubeVideoPage PeerTubeVideo.Model
    | PeerTubeAccountPage PeerTubeAccount.Model
    | AboutPage About.Model
    | ParticipatePage Participate.Model
    | NewsletterPage Newsletter.Model
    | CGUPage CGU.Model
    | ConventionPage Convention.Model
    | PrivacyPolicyPage PrivacyPolicy.Model
    | AdminPage Admin.Model
    | VideoPage Video.Model
    | LoginPage Login.Model
    | RegisterPage Register.Model
    | ResetPasswordPage ResetPassword.Model
    | SetNewPasswordPage SetNewPassword.Model
    | ActivatePage Activate.Model
    | ProfilePage Profile.Model
    | CommentsPage Comments.Model
    | NotFound


type alias Model =
    { navKey : Nav.Key
    , page : Page
    , session : Session
    }


type Msg
    = HomeMsg Home.Msg
    | PeerTubeMsg PeerTube.Msg
    | PeerTubeVideoMsg PeerTubeVideo.Msg
    | PeerTubeAccountMsg PeerTubeAccount.Msg
    | AboutMsg About.Msg
    | ParticipateMsg Participate.Msg
    | NewsletterMsg Newsletter.Msg
    | CGUMsg CGU.Msg
    | ConventionMsg Convention.Msg
    | PrivacyPolicyMsg PrivacyPolicy.Msg
    | AdminMsg Admin.Msg
    | VideoMsg Video.Msg
    | LoginMsg Login.Msg
    | RegisterMsg Register.Msg
    | ResetPasswordMsg ResetPassword.Msg
    | SetNewPasswordMsg SetNewPassword.Msg
    | ActivateMsg Activate.Msg
    | ProfileMsg Profile.Msg
    | CommentsMsg Comments.Msg
    | UrlChanged Url
    | UrlRequested Browser.UrlRequest
    | AdjustTimeZone Time.Zone


setRoute : Url -> Model -> ( Model, Cmd Msg )
setRoute url oldModel =
    let
        maybeRoute =
            Route.fromUrl url

        session =
            oldModel.session

        model =
            -- Save the current URL.
            { oldModel | session = { session | prevUrl = session.url, url = url } }

        toPage page subInit subMsg =
            let
                ( subModel, subCmds ) =
                    subInit model.session
            in
            ( { model | page = page subModel }
            , Cmd.batch
                [ Cmd.map subMsg subCmds
                , Ports.newURL <| ( Url.toString url, subModel.title )
                ]
            )
    in
    case maybeRoute of
        Nothing ->
            ( { model | page = NotFound }
            , Cmd.none
            )

        Just Route.Home ->
            toPage HomePage Home.init HomeMsg

        Just Route.PeerTube ->
            toPage PeerTubePage PeerTube.init PeerTubeMsg

        Just (Route.PeerTubeVideo videoID) ->
            toPage PeerTubeVideoPage (PeerTubeVideo.init videoID) PeerTubeVideoMsg

        Just (Route.PeerTubeAccount accountName) ->
            toPage PeerTubeAccountPage (PeerTubeAccount.init accountName) PeerTubeAccountMsg

        Just Route.About ->
            toPage AboutPage About.init AboutMsg

        Just Route.Participate ->
            toPage ParticipatePage Participate.init ParticipateMsg

        Just Route.Newsletter ->
            toPage NewsletterPage Newsletter.init NewsletterMsg

        Just Route.CGU ->
            toPage CGUPage CGU.init CGUMsg

        Just Route.Convention ->
            toPage ConventionPage Convention.init ConventionMsg

        Just Route.PrivacyPolicy ->
            toPage PrivacyPolicyPage PrivacyPolicy.init PrivacyPolicyMsg

        Just Route.Admin ->
            toPage AdminPage Admin.init AdminMsg

        Just (Route.Video videoID title) ->
            toPage VideoPage (Video.init videoID title) VideoMsg

        Just Route.Login ->
            toPage LoginPage Login.init LoginMsg

        Just Route.Register ->
            toPage RegisterPage Register.init RegisterMsg

        Just Route.ResetPassword ->
            toPage ResetPasswordPage ResetPassword.init ResetPasswordMsg

        Just (Route.SetNewPassword email temporaryPassword) ->
            toPage SetNewPasswordPage (SetNewPassword.init email temporaryPassword) SetNewPasswordMsg

        Just (Route.Activate username activationKey) ->
            toPage ActivatePage (Activate.init username activationKey) ActivateMsg

        Just (Route.Profile maybeProfile) ->
            -- Treat a special case: going to the `/profil` url without a profile ID, but the user is connected
            -- and has a profile: if that happens, redirect to `/profil/<profile id>`.
            case ( maybeProfile, session.userData.profile ) of
                ( Nothing, Just userProfile ) ->
                    ( oldModel, Route.pushUrl oldModel.navKey <| Route.Profile (Just userProfile) )

                ( _, _ ) ->
                    toPage ProfilePage (Profile.init maybeProfile) ProfileMsg

        Just Route.Comments ->
            toPage CommentsPage Comments.init CommentsMsg


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        userData =
            -- Decode a string from the "loginForm" field in the value (the stringified session data)
            Decode.decodeValue (Decode.field "loginForm" Decode.string) flags
                -- Decode a loginForm from the value
                |> Result.andThen (Decode.decodeString decodeUserData)
                |> Result.withDefault emptyUserData

        version =
            -- Decode a string from the "version" field in the value
            Decode.decodeValue (Decode.field "version" Decode.string) flags
                |> Result.withDefault "dev"

        kintoURL =
            -- Decode a string from the "kintoUrl" field in the value
            Decode.decodeValue (Decode.field "kintoURL" Decode.string) flags
                |> Result.withDefault "No Kinto URL"

        navigatorShare =
            -- Decode a boolean from the "navigatorShare" field in the value
            Decode.decodeValue (Decode.field "navigatorShare" Decode.bool) flags
                |> Result.withDefault False

        staticFiles =
            -- Decode a StaticFiles record from the "staticFiles" field in the value
            Decode.decodeValue (Decode.field "staticFiles" decodeStaticFiles) flags
                |> Result.withDefault emptyStaticFiles

        session : Session
        session =
            { userData = userData
            , timezone = Time.utc
            , version = version
            , kintoURL = kintoURL
            , navigatorShare = navigatorShare
            , staticFiles = staticFiles
            , url = url
            , prevUrl = url
            }

        ( routeModel, routeCmd ) =
            setRoute url
                { navKey = navKey
                , page = HomePage (Home.init session |> (\( model, _ ) -> model))
                , session = session
                }
    in
    ( routeModel, Cmd.batch [ routeCmd, Task.perform AdjustTimeZone Time.here ] )



---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ page, session } as model) =
    let
        toPage toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd ) =
                    subUpdate subMsg subModel
            in
            ( { model | page = toModel newModel }
            , Cmd.map toMsg newCmd
            )
    in
    case ( msg, page ) of
        ( HomeMsg homeMsg, HomePage homeModel ) ->
            toPage HomePage HomeMsg (Home.update session) homeMsg homeModel

        ( PeerTubeMsg peerTubeMsg, PeerTubePage peerTubeModel ) ->
            toPage PeerTubePage PeerTubeMsg (PeerTube.update session) peerTubeMsg peerTubeModel

        ( PeerTubeVideoMsg peerTubeVideoMsg, PeerTubeVideoPage peerTubeVideoModel ) ->
            toPage PeerTubeVideoPage PeerTubeVideoMsg (PeerTubeVideo.update session) peerTubeVideoMsg peerTubeVideoModel

        ( PeerTubeAccountMsg peerTubeAccountMsg, PeerTubeAccountPage peerTubeAccountModel ) ->
            toPage PeerTubeAccountPage PeerTubeAccountMsg (PeerTubeAccount.update session) peerTubeAccountMsg peerTubeAccountModel

        ( AboutMsg aboutMsg, AboutPage aboutModel ) ->
            toPage AboutPage AboutMsg (About.update session) aboutMsg aboutModel

        ( ParticipateMsg participateMsg, ParticipatePage participateModel ) ->
            toPage ParticipatePage ParticipateMsg (Participate.update session) participateMsg participateModel

        ( NewsletterMsg newsletterMsg, NewsletterPage newsletterModel ) ->
            toPage NewsletterPage NewsletterMsg (Newsletter.update session) newsletterMsg newsletterModel

        ( ConventionMsg conventionMsg, ConventionPage conventionModel ) ->
            toPage ConventionPage ConventionMsg (Convention.update session) conventionMsg conventionModel

        ( PrivacyPolicyMsg privacyPolicyMsg, PrivacyPolicyPage privacyPolicyModel ) ->
            toPage PrivacyPolicyPage PrivacyPolicyMsg (PrivacyPolicy.update session) privacyPolicyMsg privacyPolicyModel

        ( AdminMsg adminMsg, AdminPage adminModel ) ->
            toPage AdminPage AdminMsg (Admin.update session) adminMsg adminModel

        ( VideoMsg videoMsg, VideoPage videoModel ) ->
            toPage VideoPage VideoMsg (Video.update session) videoMsg videoModel

        ( LoginMsg loginMsg, LoginPage loginModel ) ->
            let
                ( newModel, newCmd ) =
                    toPage LoginPage LoginMsg (Login.update session) loginMsg loginModel
            in
            case loginMsg of
                -- Special case: if we retrieved the user info, then the credentials are
                -- correct, and we can store them in the session for future use
                Login.UserInfoReceived (Ok userInfo) ->
                    let
                        loginForm =
                            loginModel.loginForm

                        userData =
                            { loginForm | username = userInfo.id, profile = userInfo.profile }

                        updatedSession =
                            { session | userData = userData }

                        redirectCmd =
                            case userInfo.profile of
                                Just profile ->
                                    [ redirectToPrevUrl session model ]

                                Nothing ->
                                    -- Profile not created yet.
                                    [ Route.pushUrl model.navKey <| Route.Profile Nothing ]
                    in
                    ( { newModel | session = updatedSession }
                    , Cmd.batch
                        ([ Ports.saveSession <| encodeUserData userData
                         , newCmd
                         ]
                            ++ redirectCmd
                        )
                    )

                _ ->
                    ( newModel, newCmd )

        ( RegisterMsg registerMsg, RegisterPage registerModel ) ->
            toPage RegisterPage RegisterMsg (Register.update session) registerMsg registerModel

        ( ResetPasswordMsg resetPasswordMsg, ResetPasswordPage resetPasswordModel ) ->
            toPage ResetPasswordPage ResetPasswordMsg (ResetPassword.update session) resetPasswordMsg resetPasswordModel

        ( SetNewPasswordMsg setNewPasswordMsg, SetNewPasswordPage setNewPasswordModel ) ->
            toPage SetNewPasswordPage SetNewPasswordMsg (SetNewPassword.update session) setNewPasswordMsg setNewPasswordModel

        ( ActivateMsg activateMsg, ActivatePage activateModel ) ->
            toPage ActivatePage ActivateMsg (Activate.update session) activateMsg activateModel

        ( ProfileMsg profileMsg, ProfilePage profileModel ) ->
            let
                ( newModel, newCmd ) =
                    toPage ProfilePage ProfileMsg (Profile.update session) profileMsg profileModel
            in
            case profileMsg of
                Profile.ProfileAssociated profile (Ok userInfo) ->
                    -- Special case: if we associated the profile to the user record, then
                    -- we can store the updated user and profile in the session for future use
                    let
                        userData =
                            session.userData

                        updatedUserData =
                            { userData | username = userInfo.id, profile = Just profile.id }

                        updatedSession =
                            { session | userData = updatedUserData }
                    in
                    ( { newModel | session = updatedSession }
                    , Cmd.batch
                        [ Ports.saveSession <| encodeUserData userData
                        , newCmd
                        ]
                    )

                Profile.Logout ->
                    let
                        updatedSession =
                            { session | userData = emptyUserData }
                    in
                    ( { newModel | session = updatedSession }
                    , Cmd.batch
                        [ Ports.logoutSession ()
                        , Route.pushUrl model.navKey Route.Home
                        , newCmd
                        ]
                    )

                _ ->
                    ( newModel, newCmd )

        ( CommentsMsg commentsMsg, CommentsPage commentsModel ) ->
            toPage CommentsPage CommentsMsg (Comments.update session) commentsMsg commentsModel

        ( UrlRequested urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    let
                        isStaticFile =
                            String.startsWith "/documents/" url.path

                        urlString =
                            Url.toString url

                        cmd =
                            if isStaticFile then
                                Nav.load urlString

                            else
                                Nav.pushUrl model.navKey urlString
                    in
                    ( model, cmd )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        ( UrlChanged url, _ ) ->
            if url.path == model.session.url.path then
                -- Link was to an anchor in the same page.
                ( model, Cmd.none )

            else
                setRoute url model

        ( AdjustTimeZone zone, _ ) ->
            let
                modelSession =
                    model.session
            in
            ( { model | session = { modelSession | timezone = zone } }, Cmd.none )

        ( _, NotFound ) ->
            ( { model | page = NotFound }
            , Cmd.none
            )

        ( _, _ ) ->
            ( model
            , Cmd.none
            )


redirectToPrevUrl : Session -> Model -> Cmd Msg
redirectToPrevUrl session model =
    let
        shouldRedirectToPrevPage =
            case Route.fromUrl session.prevUrl of
                Nothing ->
                    False

                Just Route.Login ->
                    False

                Just (Route.Activate _ _) ->
                    False

                Just Route.ResetPassword ->
                    False

                Just (Route.SetNewPassword _ _) ->
                    False

                _ ->
                    True
    in
    if session.prevUrl /= session.url && shouldRedirectToPrevPage then
        Nav.pushUrl model.navKey <| Url.toString session.prevUrl

    else
        Route.pushUrl model.navKey Route.Home



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ case model.page of
            HomePage _ ->
                Sub.none

            PeerTubePage _ ->
                Sub.none

            PeerTubeVideoPage _ ->
                Sub.none

            PeerTubeAccountPage _ ->
                Sub.none

            AboutPage _ ->
                Sub.none

            ParticipatePage _ ->
                Sub.batch
                    ([ Ports.videoObjectUrl Participate.VideoObjectUrlReceived
                     , Ports.progressUpdate Participate.ProgressUpdated
                     , Ports.videoSubmitted Participate.AttachmentSent
                     ]
                        |> List.map (Platform.Sub.map ParticipateMsg)
                    )

            NewsletterPage _ ->
                Sub.none

            CGUPage _ ->
                Sub.none

            ConventionPage _ ->
                Sub.none

            PrivacyPolicyPage _ ->
                Sub.none

            AdminPage _ ->
                Sub.none

            VideoPage _ ->
                Sub.batch
                    ([ Ports.attachmentSubmitted Video.AttachmentSent
                     , Ports.progressUpdate Video.ProgressUpdated
                     ]
                        |> List.map (Platform.Sub.map VideoMsg)
                    )

            LoginPage _ ->
                Sub.none

            RegisterPage _ ->
                Sub.none

            ResetPasswordPage _ ->
                Sub.none

            SetNewPasswordPage _ ->
                Sub.none

            ActivatePage _ ->
                Sub.none

            ProfilePage _ ->
                Sub.none

            CommentsPage _ ->
                Sub.none

            NotFound ->
                Sub.none
        ]



---- VIEW ----


view : Model -> Document Msg
view model =
    let
        pageConfig =
            Page.Config model.session

        mapMsg msg ( title, content ) =
            ( title, content |> List.map (Html.map msg) )
    in
    case model.page of
        HomePage homeModel ->
            Home.view model.session homeModel
                |> mapMsg HomeMsg
                |> Page.frame (pageConfig Page.Home)

        PeerTubePage peerTubeModel ->
            PeerTube.view model.session peerTubeModel
                |> mapMsg PeerTubeMsg
                |> Page.frame (pageConfig Page.PeerTube)

        PeerTubeVideoPage peerTubeVideoModel ->
            PeerTubeVideo.view model.session peerTubeVideoModel
                |> mapMsg PeerTubeVideoMsg
                |> Page.frame (pageConfig Page.PeerTubeVideo)

        PeerTubeAccountPage peerTubeAccountModel ->
            PeerTubeAccount.view model.session peerTubeAccountModel
                |> mapMsg PeerTubeAccountMsg
                |> Page.frame (pageConfig Page.PeerTubeAccount)

        AboutPage aboutModel ->
            About.view model.session aboutModel
                |> mapMsg AboutMsg
                |> Page.frame (pageConfig Page.About)

        ParticipatePage participateModel ->
            Participate.view model.session participateModel
                |> mapMsg ParticipateMsg
                |> Page.frame (pageConfig Page.Participate)

        NewsletterPage newsletterModel ->
            Newsletter.view model.session newsletterModel
                |> mapMsg NewsletterMsg
                |> Page.frame (pageConfig Page.Newsletter)

        CGUPage cguModel ->
            CGU.view model.session cguModel
                |> mapMsg CGUMsg
                |> Page.frame (pageConfig Page.CGU)

        ConventionPage conventionModel ->
            Convention.view model.session conventionModel
                |> mapMsg ConventionMsg
                |> Page.frame (pageConfig Page.Convention)

        PrivacyPolicyPage privacyPolicyModel ->
            PrivacyPolicy.view model.session privacyPolicyModel
                |> mapMsg PrivacyPolicyMsg
                |> Page.frame (pageConfig Page.PrivacyPolicy)

        AdminPage adminModel ->
            Admin.view model.session adminModel
                |> mapMsg AdminMsg
                |> Page.frame (pageConfig Page.Admin)

        VideoPage videoModel ->
            Video.view model.session videoModel
                |> mapMsg VideoMsg
                |> Page.frame (pageConfig Page.Video)

        LoginPage loginModel ->
            Login.view model.session loginModel
                |> mapMsg LoginMsg
                |> Page.frame (pageConfig Page.Login)

        RegisterPage registerModel ->
            Register.view model.session registerModel
                |> mapMsg RegisterMsg
                |> Page.frame (pageConfig Page.Register)

        ResetPasswordPage resetPasswordModel ->
            ResetPassword.view model.session resetPasswordModel
                |> mapMsg ResetPasswordMsg
                |> Page.frame (pageConfig Page.ResetPassword)

        SetNewPasswordPage setNewPasswordModel ->
            SetNewPassword.view model.session setNewPasswordModel
                |> mapMsg SetNewPasswordMsg
                |> Page.frame (pageConfig Page.SetNewPassword)

        ActivatePage activateModel ->
            Activate.view model.session activateModel
                |> mapMsg ActivateMsg
                |> Page.frame (pageConfig Page.Activate)

        ProfilePage profileModel ->
            Profile.view model.session profileModel
                |> mapMsg ProfileMsg
                |> Page.frame (pageConfig Page.Profile)

        CommentsPage commentsModel ->
            Comments.view model.session commentsModel
                |> mapMsg CommentsMsg
                |> Page.frame (pageConfig Page.Comments)

        NotFound ->
            ( "Not Found", [ Html.text "Not found" ] )
                |> Page.frame (pageConfig Page.NotFound)



---- MAIN ----


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = UrlRequested
        }

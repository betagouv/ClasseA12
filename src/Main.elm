module Main exposing (main)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Data.PeerTube
import Data.Session exposing (Session)
import Html exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Page.About as About
import Page.Activate as Activate
import Page.Admin as Admin
import Page.CGU as CGU
import Page.Comments as Comments
import Page.Common.Components
import Page.Convention as Convention
import Page.Home as Home
import Page.Login as Login
import Page.Participate as Participate
import Page.PrivacyPolicy as PrivacyPolicy
import Page.Profile as Profile
import Page.Register as Register
import Page.ResetPassword as ResetPassword
import Page.Search as Search
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
    | SearchPage Search.Model
    | AboutPage About.Model
    | ParticipatePage Participate.Model
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

    -- Partially applied Route.pushUrl with the navKey
    , pushUrl : Route -> Cmd Msg
    }


type Msg
    = HomeMsg Home.Msg
    | SearchMsg Search.Msg
    | AboutMsg About.Msg
    | ParticipateMsg Participate.Msg
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
    | UpdateSearch String
    | SubmitSearch


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

        Just (Route.Search search) ->
            toPage SearchPage (Search.init search) SearchMsg

        Just Route.About ->
            toPage AboutPage About.init AboutMsg

        Just Route.Participate ->
            toPage ParticipatePage Participate.init ParticipateMsg

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
            toPage ProfilePage (Profile.init maybeProfile) ProfileMsg

        Just Route.Comments ->
            toPage CommentsPage Comments.init CommentsMsg


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        userToken =
            -- Decode a string from the "userToken" field in the value (stored in the localstorage)
            Decode.decodeValue (Decode.field "userToken" Decode.string) flags
                -- Decode a userToken from the value
                |> Result.andThen (Decode.decodeString Data.PeerTube.userTokenDecoder)
                |> Result.map Just
                |> Result.withDefault Nothing

        userInfo =
            -- Decode a string from the "userInfo" field in the value (stored in the localstorage)
            Decode.decodeValue (Decode.field "userInfo" Decode.string) flags
                -- Decode a userInfo from the value
                |> Result.andThen (Decode.decodeString Data.Session.userInfoDecoder)
                |> Result.map Just
                |> Result.withDefault Nothing

        version =
            -- Decode a string from the "version" field in the value
            Decode.decodeValue (Decode.field "version" Decode.string) flags
                |> Result.withDefault "dev"

        peerTubeURL =
            -- Decode a string from the "peerTubeURL" field in the value
            Decode.decodeValue (Decode.field "peerTubeURL" Decode.string) flags
                |> Result.withDefault "No PeerTube URL"

        filesURL =
            -- Decode a string from the "filesURL" field in the value
            Decode.decodeValue (Decode.field "filesURL" Decode.string) flags
                |> Result.withDefault "No Files URL"

        navigatorShare =
            -- Decode a boolean from the "navigatorShare" field in the value
            Decode.decodeValue (Decode.field "navigatorShare" Decode.bool) flags
                |> Result.withDefault False

        session : Session
        session =
            { timezone = Time.utc
            , version = version
            , peerTubeURL = peerTubeURL
            , filesURL = filesURL
            , navigatorShare = navigatorShare
            , url = url
            , prevUrl = url
            , userToken = userToken
            , userInfo = userInfo
            , search = ""
            }

        ( routeModel, routeCmd ) =
            setRoute url
                { navKey = navKey
                , page = HomePage (Home.init session |> (\( model, _ ) -> model))
                , session = session
                , pushUrl = Route.pushUrl navKey
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

        toPageWithSessionMsg toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd, sessionCmd ) =
                    subUpdate subMsg subModel
            in
            ( { model | page = toModel newModel }
            , Cmd.map toMsg newCmd
            , sessionCmd
            )
                |> Data.Session.interpretMsg
    in
    case ( msg, page ) of
        ( HomeMsg homeMsg, HomePage homeModel ) ->
            toPage HomePage HomeMsg (Home.update session) homeMsg homeModel

        ( SearchMsg searchMsg, SearchPage searchModel ) ->
            toPage SearchPage SearchMsg (Search.update session) searchMsg searchModel

        ( AboutMsg aboutMsg, AboutPage aboutModel ) ->
            toPage AboutPage AboutMsg (About.update session) aboutMsg aboutModel

        ( ParticipateMsg participateMsg, ParticipatePage participateModel ) ->
            toPageWithSessionMsg ParticipatePage ParticipateMsg (Participate.update session) participateMsg participateModel

        ( ConventionMsg conventionMsg, ConventionPage conventionModel ) ->
            toPage ConventionPage ConventionMsg (Convention.update session) conventionMsg conventionModel

        ( PrivacyPolicyMsg privacyPolicyMsg, PrivacyPolicyPage privacyPolicyModel ) ->
            toPage PrivacyPolicyPage PrivacyPolicyMsg (PrivacyPolicy.update session) privacyPolicyMsg privacyPolicyModel

        ( AdminMsg adminMsg, AdminPage adminModel ) ->
            toPageWithSessionMsg AdminPage AdminMsg (Admin.update session) adminMsg adminModel

        ( VideoMsg videoMsg, VideoPage videoModel ) ->
            toPageWithSessionMsg VideoPage VideoMsg (Video.update session) videoMsg videoModel

        ( LoginMsg loginMsg, LoginPage loginModel ) ->
            toPageWithSessionMsg LoginPage LoginMsg (Login.update session) loginMsg loginModel

        ( RegisterMsg registerMsg, RegisterPage registerModel ) ->
            toPage RegisterPage RegisterMsg (Register.update session) registerMsg registerModel

        ( ResetPasswordMsg resetPasswordMsg, ResetPasswordPage resetPasswordModel ) ->
            toPage ResetPasswordPage ResetPasswordMsg (ResetPassword.update session) resetPasswordMsg resetPasswordModel

        ( SetNewPasswordMsg setNewPasswordMsg, SetNewPasswordPage setNewPasswordModel ) ->
            toPage SetNewPasswordPage SetNewPasswordMsg (SetNewPassword.update session) setNewPasswordMsg setNewPasswordModel

        ( ActivateMsg activateMsg, ActivatePage activateModel ) ->
            toPage ActivatePage ActivateMsg (Activate.update session) activateMsg activateModel

        ( ProfileMsg profileMsg, ProfilePage profileModel ) ->
            toPageWithSessionMsg ProfilePage ProfileMsg (Profile.update session) profileMsg profileModel

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

        ( UpdateSearch search, _ ) ->
            let
                modelSession =
                    model.session
            in
            ( { model | session = { modelSession | search = search } }, Cmd.none )

        ( SubmitSearch, _ ) ->
            ( model, Route.pushUrl model.navKey (Route.Search <| Just model.session.search) )

        ( _, NotFound ) ->
            ( { model | page = NotFound }
            , Cmd.none
            )

        ( _, _ ) ->
            ( model
            , Cmd.none
            )



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ case model.page of
            HomePage _ ->
                Sub.none

            SearchPage _ ->
                Sub.none

            AboutPage _ ->
                Sub.none

            ParticipatePage _ ->
                Sub.batch
                    ([ Ports.videoObjectUrl Participate.VideoObjectUrlReceived
                     , Ports.progressUpdate Participate.ProgressUpdated
                     , Ports.videoSubmitted Participate.VideoUploaded
                     ]
                        |> List.map (Platform.Sub.map ParticipateMsg)
                    )

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
                    ([ Ports.progressUpdate Video.ProgressUpdated
                     , Ports.attachmentSubmitted Video.AttachmentSent
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
            Page.Config model.session UpdateSearch SubmitSearch

        mapMsg : (msg -> Msg) -> Page.Common.Components.Document msg -> Page.Common.Components.Document Msg
        mapMsg msg { title, pageTitle, pageSubTitle, body } =
            { title = title
            , pageTitle = pageTitle
            , pageSubTitle = pageSubTitle
            , body = body |> List.map (Html.map msg)
            }
    in
    case model.page of
        HomePage homeModel ->
            Home.view model.session homeModel
                |> mapMsg HomeMsg
                |> Page.frame (pageConfig Page.Home)

        SearchPage searchModel ->
            Search.view model.session searchModel
                |> mapMsg SearchMsg
                |> Page.frame (pageConfig <| Page.Search searchModel.keyword)

        AboutPage aboutModel ->
            About.view model.session aboutModel
                |> mapMsg AboutMsg
                |> Page.frame (pageConfig Page.About)

        ParticipatePage participateModel ->
            Participate.view model.session participateModel
                |> mapMsg ParticipateMsg
                |> Page.frame (pageConfig Page.Participate)

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
            let
                title =
                    "Page introuvable"
            in
            { title = title
            , pageTitle = title
            , pageSubTitle = title
            , body = [ Html.text title ]
            }
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

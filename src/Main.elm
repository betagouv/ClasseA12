port module Main exposing (main)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Data.Kinto
import Data.Session exposing (Session, decodeSessionData, emptyLoginForm)
import Html exposing (..)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Kinto
import Page.About as About
import Page.Admin as Admin
import Page.CGU as CGU
import Page.Convention as Convention
import Page.Home as Home
import Page.Video as Video
import Page.Newsletter as Newsletter
import Page.Participate as Participate
import Page.PrivacyPolicy as PrivacyPolicy
import Platform.Sub
import Ports
import Request.KintoVideo exposing (getVideoList)
import Route exposing (Route)
import Task
import Time
import Url exposing (Url)
import Views.Page as Page


type alias Flags =
    Encode.Value


type Page
    = HomePage Home.Model
    | AboutPage About.Model
    | ParticipatePage Participate.Model
    | NewsletterPage Newsletter.Model
    | CGUPage CGU.Model
    | ConventionPage Convention.Model
    | PrivacyPolicyPage PrivacyPolicy.Model
    | AdminPage Admin.Model
    | VideoPage Video.Model
    | NotFound


type alias Model =
    { navKey : Nav.Key
    , page : Page
    , session : Session
    }


type Msg
    = HomeMsg Home.Msg
    | AboutMsg About.Msg
    | ParticipateMsg Participate.Msg
    | NewsletterMsg Newsletter.Msg
    | CGUMsg CGU.Msg
    | ConventionMsg Convention.Msg
    | PrivacyPolicyMsg PrivacyPolicy.Msg
    | AdminMsg Admin.Msg
    | VideoMsg Video.Msg
    | RouteChanged (Maybe Route)
    | UrlChanged Url
    | UrlRequested Browser.UrlRequest
    | VideoListReceived (Result Kinto.Error Data.Kinto.VideoList)
    | AdjustTimeZone Time.Zone


setRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
setRoute maybeRoute model =
    let
        toPage page subInit subMsg =
            let
                ( subModel, subCmds ) =
                    subInit model.session
            in
            ( { model | page = page subModel }
            , Cmd.batch
                [ Cmd.map subMsg subCmds
                , Ports.newURL "new url"
                ]
            )
    in
    case maybeRoute of
        Nothing ->
            ( { model | page = NotFound }
            , Cmd.none
            )

        Just Route.Home ->
            let
                ( homeModel, commands ) =
                    toPage HomePage Home.init HomeMsg
            in
            ( homeModel
              -- When loading the home for the first time, request the list of videos
            , getVideoList VideoListReceived
            )

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

        Just (Route.Video videoID) ->
            toPage VideoPage (Video.init videoID) VideoMsg


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        loginForm =
            -- Decode a string from the value (the stringified session data)
            Decode.decodeValue Decode.string flags
                -- Decode a loginForm from the value
                |> Result.andThen (Decode.decodeString decodeSessionData)
                |> Result.withDefault emptyLoginForm

        session : Session
        session =
            { videoData = Data.Kinto.Requested
            , loginForm = loginForm
            , timezone = Time.utc
            }

        ( routeModel, routeCmd ) =
            setRoute (Route.fromUrl url)
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
            let
                ( newModel, newCmd ) =
                    toPage AdminPage AdminMsg (Admin.update session) adminMsg adminModel
            in
            case adminMsg of
                -- Special case: if we retrieved the list of upcoming video using the credentials, then they are
                -- correct, and we can store them in the session for future use
                Admin.VideoListFetched (Ok _) ->
                    let
                        updatedSession =
                            { session | loginForm = adminModel.loginForm }
                    in
                    ( { newModel | session = updatedSession }, newCmd )

                -- Special case: on logout, remove the credentials from the session
                Admin.Logout ->
                    let
                        updatedSession =
                            { session | loginForm = emptyLoginForm }
                    in
                    ( { newModel | session = updatedSession }, newCmd )

                _ ->
                    ( newModel, newCmd )

        ( VideoMsg videoMsg, VideoPage videoModel ) ->
            toPage VideoPage VideoMsg (Video.update session) videoMsg videoModel

        ( RouteChanged route, _ ) ->
            setRoute route model

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
            setRoute (Route.fromUrl url) model

        ( VideoListReceived (Ok videoList), _ ) ->
            let
                modelSession =
                    model.session
            in
            ( { model | session = { modelSession | videoData = Data.Kinto.Received videoList } }, Cmd.none )

        ( VideoListReceived (Err error), _ ) ->
            let
                modelSession =
                    model.session
            in
            ( { model | session = { modelSession | videoData = Data.Kinto.Failed error } }, Cmd.none )

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



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ case model.page of
            HomePage _ ->
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

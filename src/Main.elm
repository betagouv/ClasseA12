port module Main exposing (main)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Data.Session exposing (Session, VideoData(..))
import Html exposing (..)
import Http
import Json.Decode as Decode
import Page.About as About
import Page.CGU as CGU
import Page.Convention as Convention
import Page.Home as Home
import Page.Newsletter as Newsletter
import Page.Participate as Participate
import Page.PrivacyPolicy as PrivacyPolicy
import Platform.Sub
import Ports
import Request.Vimeo as Vimeo
import Route exposing (Route)
import Url exposing (Url)
import Views.Page as Page


type alias Flags =
    {}


type Page
    = HomePage Home.Model
    | AboutPage About.Model
    | ParticipatePage Participate.Model
    | NewsletterPage Newsletter.Model
    | CGUPage CGU.Model
    | ConventionPage Convention.Model
    | PrivacyPolicyPage PrivacyPolicy.Model
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
    | RouteChanged (Maybe Route)
    | UrlChanged Url
    | UrlRequested Browser.UrlRequest
    | VideoListReceived (Result Http.Error String)
    | VideoListParsed (Result Decode.Error (List Data.Session.Video))


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
            , Cmd.batch
                [ commands

                -- When loading the home for the first time, request the list of videos
                , Vimeo.getRSS model.session |> Http.send VideoListReceived
                ]
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


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        -- you'll usually want to retrieve and decode serialized session
        -- information from flags here
        session : Session
        session =
            { videoData = Fetching }
    in
    setRoute (Route.fromUrl url)
        { navKey = navKey
        , page = HomePage (Home.init session |> (\( model, _ ) -> model))
        , session = session
        }



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

        ( RouteChanged route, _ ) ->
            setRoute route model

        ( UrlRequested urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl model.navKey (Url.toString url)
                    )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        ( UrlChanged url, _ ) ->
            setRoute (Route.fromUrl url) model

        ( VideoListReceived (Ok rss), _ ) ->
            -- Received the video list rss, send it to the port to parse it
            ( model, Ports.parseRSS rss )

        ( VideoListReceived (Err error), _ ) ->
            let
                modelSession =
                    model.session
            in
            ( { model | session = { modelSession | videoData = Error <| Vimeo.errorToString error } }, Cmd.none )

        ( VideoListParsed (Ok videoList), _ ) ->
            let
                modelSession =
                    model.session
            in
            ( { model | session = { modelSession | videoData = Received videoList } }, Cmd.none )

        ( VideoListParsed (Err error), _ ) ->
            let
                modelSession =
                    model.session
            in
            ( { model | session = { modelSession | videoData = Error <| Decode.errorToString error } }, Cmd.none )

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
        [ Ports.parsedVideoList (Data.Session.decodeVideoList >> VideoListParsed) -- Always sub on the parsedVideoList incoming port
        , case model.page of
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

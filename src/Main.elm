port module Main exposing (main)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Data.Session exposing (Session, VideoData(..))
import Html exposing (..)
import Http
import Json.Decode as Decode
import Page.About as About
import Page.Home as Home
import Page.Newsletter as Newsletter
import Page.Participate as Participate
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
    | NotFound


type alias Model =
    { navKey : Nav.Key
    , page : Page
    , session : Session
    , isMenuActive : Bool
    }


type Msg
    = HomeMsg Home.Msg
    | AboutMsg About.Msg
    | ParticipateMsg Participate.Msg
    | NewsletterMsg Newsletter.Msg
    | RouteChanged (Maybe Route)
    | UrlChanged Url
    | UrlRequested Browser.UrlRequest
    | BurgerClicked
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
            , Cmd.map subMsg subCmds
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
        , isMenuActive = False
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

        ( BurgerClicked, _ ) ->
            ( { model | isMenuActive = not model.isMenuActive }, Cmd.none )

        ( VideoListReceived (Ok rss), _ ) ->
            -- Received the video list rss, send it to the port to parse it
            ( model, parseRSS rss )

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
        [ parsedVideoList (Data.Session.decodeVideoList >> VideoListParsed) -- Always sub on the parsedVideoList incoming port
        , case model.page of
            HomePage _ ->
                Sub.none

            AboutPage _ ->
                Sub.none

            ParticipatePage _ ->
                Sub.none

            NewsletterPage _ ->
                Sub.none

            NotFound ->
                Sub.none
        ]



---- VIEW ----


view : Model -> Document Msg
view model =
    let
        pageConfig =
            Page.Config model.session model.isMenuActive BurgerClicked

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

        NotFound ->
            ( "Not Found", [ Html.text "Not found" ] )
                |> Page.frame (pageConfig Page.NotFound)



---- PORTS ----


port parseRSS : String -> Cmd msg


port parsedVideoList : (Decode.Value -> msg) -> Sub msg



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

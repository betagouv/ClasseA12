module Page.PeerTubeVideo exposing (Model, Msg, init, update, view)

import Data.PeerTube exposing (RemoteData(..), Video)
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Http
import Request.PeerTube exposing (getVideo)
import Route


type alias Model =
    { videoId : String, title : String, videoData : RemoteData Video }


type Msg
    = NoOp
    | VideoReceived (Result Http.Error Video)


init : String -> Session -> ( Model, Cmd Msg )
init videoId session =
    ( { videoId = videoId, title = "View video", videoData = Requested }, getVideo videoId VideoReceived )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        VideoReceived (Ok video) ->
            ( { model | videoData = Received video }, Cmd.none )

        VideoReceived (Err error) ->
            ( { model | videoData = Failed "Something went wrong" }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view session model =
    let
        videoElement : List (H.Html Msg)
        videoElement =
            case model.videoData of
                Received video ->
                    [ H.h1 [] [ H.text video.name ]
                    , H.embed
                        [ HA.src ("https://peertube.scopyleft.fr" ++ video.embedPath)
                        , HA.width 1000
                        , HA.height 800
                        ]
                        []
                    , H.a
                        [ Route.href <| Route.PeerTubeAccount video.account.name
                        ]
                        [ H.text ("Proposé par " ++ video.account.name) ]
                    ]

                Requested ->
                    [ H.text "Chargement…" ]

                _ ->
                    [ H.text "tout le reste" ]
    in
    ( model.title
    , [ H.article [] videoElement ]
    )

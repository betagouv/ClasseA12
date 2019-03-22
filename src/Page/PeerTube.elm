module Page.PeerTube exposing (Model, Msg, init, update, view)

import Data.PeerTube exposing (Account, Video)
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Http
import Request.PeerTube exposing (getVideoList)


type alias Model =
    { title : String, videoList : List Video }


type Msg
    = NoOp
    | VideoListReceived (Result Http.Error (List Video))


init : Session -> ( Model, Cmd Msg )
init session =
    ( { title = "PeerTube testouille", videoList = [] }, getVideoList VideoListReceived )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        VideoListReceived response ->
            let
                videoList : List Video
                videoList =
                    response
                        |> Result.withDefault []
            in
            ( { model | videoList = videoList }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view session model =
    ( model.title
    , [ H.ul []
            (model.videoList
                |> List.map
                    (\video ->
                        H.li []
                            [ H.img
                                [ HA.src ("https://peertube.scopyleft.fr" ++ video.previewPath)
                                , HA.width 400
                                , HA.height 200
                                ]
                                []
                            , H.caption [] [ H.text video.name ]
                            , H.span [] [ H.text video.account.displayName ]
                            ]
                    )
            )
      ]
    )

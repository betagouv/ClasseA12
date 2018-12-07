module Page.Video exposing (Model, Msg(..), init, update, view)

import Data.Kinto
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Kinto
import Page.Utils
import Request.KintoVideo
import Time


type alias Model =
    { videoID : String
    , video : Data.Kinto.KintoData Data.Kinto.Video
    }


type Msg
    = Noop
    | VideoReceived (Result Kinto.Error Data.Kinto.Video)


init : String -> Session -> ( Model, Cmd Msg )
init videoID session =
    ( { videoID = videoID
      , video = Data.Kinto.Requested
      }
    , Request.KintoVideo.getVideo videoID VideoReceived
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )

        VideoReceived (Ok video) ->
            ( { model | video = Data.Kinto.Received video }, Cmd.none )

        VideoReceived (Err error) ->
            ( { model | video = Data.Kinto.Failed error }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view { timezone } { video } =
    ( "Classe à 12 ?"
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src "/logo_ca12.png", HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "Vidéo" ]
                , viewTitle video
                ]
            ]
      , H.div [ HA.class "main" ]
            [ H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ viewVideo timezone video
                    ]
                ]
            ]
      ]
    )


viewTitle : Data.Kinto.KintoData Data.Kinto.Video -> H.Html Msg
viewTitle videoData =
    case videoData of
        Data.Kinto.Received video ->
            H.p [] [ H.text video.title ]

        _ ->
            H.p [] []


viewVideo : Time.Zone -> Data.Kinto.KintoData Data.Kinto.Video -> H.Html Msg
viewVideo timezone videoData =
    case videoData of
        Data.Kinto.Received video ->
            viewVideoDetails timezone video

        Data.Kinto.Requested ->
            H.p [] [ H.text "Chargement de la vidéo en cours..." ]

        _ ->
            H.p [] [ H.text "Vidéo non trouvée" ]

viewVideoDetails : Time.Zone -> Data.Kinto.Video -> H.Html Msg
viewVideoDetails timezone video =
    let
        keywordsNode =
            if video.keywords /= [] then
                [ H.div []
                    (List.map
                        (\keyword ->
                            H.div [ HA.class "label" ]
                                [ H.text keyword ]
                        )
                        video.keywords
                    )
                ]

            else
                []

        detailsNodes =
            [ H.div [ ]
                [ Page.Utils.viewVideoPlayer video.attachment
                , H.h3 [] [ H.text video.title ]
                , H.div []
                    [ H.time [] [ H.text <| Page.Utils.posixToDate timezone video.creation_date ] ]
                , H.p [] [ H.text video.description ]
                ]
            ]
    in
    H.div
        []
        (detailsNodes ++ keywordsNode)
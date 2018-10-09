module Page.Home exposing (Model, Msg(..), init, update, view)

import Data.Session exposing (Session, VideoData(..))
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http


type alias Model =
    { search : String }


type Msg
    = UpdateSearch String


init : Session -> ( Model, Cmd Msg )
init session =
    ( { search = "" }, Cmd.none )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        UpdateSearch newSearch ->
            ( { model | search = newSearch }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view session model =
    ( "Liste des vidéos"
    , case session.videoData of
        Fetching ->
            [ H.text "Chargement des vidéos..." ]

        Received videoList ->
            viewVideoList model.search videoList

        Error error ->
            [ H.text <| "Erreur lors du chargement des videos: " ++ error ]
    )


viewVideoList : String -> List Data.Session.Video -> List (H.Html Msg)
viewVideoList search videoList =
    let
        filteredVideoList =
            videoList
                |> List.filter (\video -> String.contains search video.title)
    in
    [ H.div
        [ HA.class "box" ]
        [ H.div [ HA.class "field has-addons" ]
            [ H.div [ HA.class "control is-expanded" ]
                [ H.input
                    [ HA.class "input"
                    , HA.type_ "search"
                    , HA.placeholder "Search video titles"
                    , HA.value search
                    , HE.onInput UpdateSearch
                    ]
                    []
                ]
            , H.div [ HA.class "control" ]
                [ H.a [ HA.class "button is-info" ] [ H.text "Search" ] ]
            ]
        ]
    , H.div [ HA.class "row columns is-multiline" ]
        (filteredVideoList
            |> List.map
                (\video ->
                    H.div [ HA.class "column is-one-quarter" ]
                        [ H.a [ HA.href video.link ]
                            [ H.div [ HA.class "card large round" ]
                                [ H.div [ HA.class "card-image " ]
                                    [ H.figure [ HA.class "image" ]
                                        [ H.img
                                            [ HA.src video.thumbnail
                                            , HA.alt <| "Thumbnail of the video titled: " ++ video.title
                                            ]
                                            []
                                        ]
                                    ]
                                , H.div [ HA.class "card-content" ]
                                    [ H.div [ HA.class "content" ]
                                        [ H.text video.title
                                        , H.p [ HA.class "video-date" ] [ H.text video.pubDate ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                )
        )
    ]

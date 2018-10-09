module Page.Home exposing (Model, Msg(..), init, update, view)

import Data.Session exposing (Session, VideoData(..))
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Encode as Encode


type alias Model =
    { search : String
    , activeVideo : Maybe Data.Session.Video
    }


type Msg
    = UpdateSearch String
    | ShowVideo Data.Session.Video
    | HideVideo


init : Session -> ( Model, Cmd Msg )
init session =
    ( { search = "", activeVideo = Nothing }, Cmd.none )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        UpdateSearch newSearch ->
            ( { model | search = newSearch }, Cmd.none )

        ShowVideo video ->
            ( { model | activeVideo = Just video }, Cmd.none )

        HideVideo ->
            ( { model | activeVideo = Nothing }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view session model =
    ( "Liste des vidéos"
    , case session.videoData of
        Fetching ->
            [ H.text "Chargement des vidéos..." ]

        Received videoList ->
            viewVideoList model videoList

        Error error ->
            [ H.text <| "Erreur lors du chargement des videos: " ++ error ]
    )


viewVideoList : { a | activeVideo : Maybe Data.Session.Video, search : String } -> List Data.Session.Video -> List (H.Html Msg)
viewVideoList ({ search } as model) videoList =
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
            |> List.map (viewVideo model)
        )
    ]


viewVideo : { a | activeVideo : Maybe Data.Session.Video } -> Data.Session.Video -> H.Html Msg
viewVideo { activeVideo } video =
    let
        active =
            activeVideo
                |> Maybe.map ((==) video)
                |> Maybe.withDefault False
    in
    H.div [ HA.class "column is-one-quarter" ]
        [ H.div
            [ HA.classList
                [ ( "modal", True )
                , ( "is-active", active )
                ]
            , HE.onClick HideVideo
            ]
            [ H.div [ HA.class "modal-background" ] []
            , H.div [ HA.class "modal-content" ]
                [ H.iframe
                    [ HA.src video.player
                    , HA.title "Partie 2 : am&eacute;nager sa classe pour co-enseigner."
                    , stringProperty "scrolling" "no"
                    , stringProperty "frameborder" "0"
                    , stringProperty "allowfullscreen" "true"
                    ]
                    []
                ]
            , H.button [ HA.class "modal-close is-large" ] []
            ]
        , H.a
            [ HA.href "#"
            , HE.onClick <| ShowVideo video
            ]
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


stringProperty : String -> String -> H.Attribute msg
stringProperty name value =
    HA.property name <| Encode.string value

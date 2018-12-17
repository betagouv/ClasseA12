module Page.Home exposing (Model, Msg(..), init, update, view)

import Data.Kinto
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Encode as Encode
import Kinto
import Page.Utils
import Time


type alias Model =
    { search : String
    , activeVideo : Maybe Data.Kinto.Video
    }


type Msg
    = UpdateSearch String
    | ToggleVideo Data.Kinto.Video


init : Session -> ( Model, Cmd Msg )
init session =
    ( { search = "", activeVideo = Nothing }, Cmd.none )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        UpdateSearch newSearch ->
            ( { model | search = newSearch }, Cmd.none )

        ToggleVideo video ->
            let
                activeVideo =
                    case model.activeVideo of
                        -- Toggle the active video
                        Just v ->
                            Nothing

                        Nothing ->
                            Just video
            in
            ( { model | activeVideo = activeVideo }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view { videoData, timezone } ({ search } as model) =
    ( "Liste des vidéos"
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__banner" ] []
            , H.div [ HA.class "hero__container" ]
                [ H.img
                    [ HA.src "/logo_ca12.png"
                    , HA.class "hero__logo"
                    ]
                    []
                , H.h1 []
                    [ H.text "Classe à 12 en vidéo" ]
                , H.p []
                    [ H.text "Échangeons nos pratiques en toute simplicité !" ]
                ]
            ]
      , H.div [ HA.class "main" ]
            [ H.section [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ H.div
                        [ HA.class "form__group light-background" ]
                        [ H.label [ HA.for "search" ]
                            [ H.text "Filtrer par mot clé :" ]
                        , H.div [ HA.class "search__group" ]
                            [ H.select
                                [ HA.id "keywords"
                                , HA.value model.search
                                , Page.Utils.onChange UpdateSearch
                                ]
                                ([ H.option [ HA.value "" ] [ H.text "Toutes les vidéos" ] ]
                                    ++ (Data.Kinto.keywordList
                                            |> List.map
                                                (\keyword ->
                                                    H.option [ HA.value keyword ] [ H.text keyword ]
                                                )
                                       )
                                )
                            , if model.search /= "" then
                                H.button
                                    [ HA.class "button-link"
                                    , HE.onClick <| UpdateSearch ""
                                    ]
                                    [ H.i [ HA.class "fa fa-times" ] [] ]

                              else
                                H.div [] []
                            ]
                        ]
                    ]
                ]
            , H.section [ HA.class "section section-grey cards" ]
                [ H.div [ HA.class "container" ]
                    (case videoData of
                        Data.Kinto.NotRequested ->
                            []

                        Data.Kinto.Requested ->
                            [ H.text "Chargement des vidéos..." ]

                        Data.Kinto.Received videoList ->
                            viewVideoList timezone model videoList

                        Data.Kinto.Failed error ->
                            [ H.text <| "Erreur lors du chargement des videos: " ++ Kinto.errorToString error ]
                    )
                ]
            ]
      ]
    )


viewVideoList : Time.Zone -> { a | activeVideo : Maybe Data.Kinto.Video, search : String } -> Data.Kinto.VideoList -> List (H.Html Msg)
viewVideoList timezone { activeVideo, search } videoList =
    let
        filteredVideoList =
            if search /= "" then
                videoList.objects
                    |> List.filter (\video -> List.member search (Data.Kinto.keywordsToList video.keywords))
            else
                videoList.objects

        videoCards =
            if filteredVideoList /= [] then
                filteredVideoList
                    |> List.map (\video -> Page.Utils.viewPublicVideo timezone video)
            else
                [ H.text "Pas de vidéos trouvée" ]

    in
    [ H.div [ HA.class "row" ]
        videoCards
    ]

module Page.Home exposing (Model, Msg(..), init, update, view)

import Data.Kinto
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Encode as Encode
import Kinto
import NaturalOrdering
import Page.Common.Components
import Page.Common.Video
import Request.KintoProfile
import Request.KintoVideo
import Route
import Set
import Task
import Time


type alias Model =
    { title : String
    , search : String
    , videoData : Data.Kinto.VideoListData
    , authorsData : Data.Kinto.KintoData Data.Kinto.ProfileList
    , timestamp : Time.Posix
    }


type Msg
    = UpdateSearch String
    | VideoListReceived (Result Kinto.Error Data.Kinto.VideoList)
    | AuthorsFetched (Result Kinto.Error Data.Kinto.ProfileList)
    | NewTimestamp Time.Posix


init : Session -> ( Model, Cmd Msg )
init session =
    ( { title = "Liste des vidéos"
      , search = ""
      , videoData = Data.Kinto.Requested
      , authorsData = Data.Kinto.NotRequested
      , timestamp = Time.millisToPosix 0
      }
    , Cmd.batch
        [ Request.KintoVideo.getVideoList session.kintoURL VideoListReceived
        , Task.perform NewTimestamp Time.now
        ]
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        UpdateSearch newSearch ->
            ( { model | search = newSearch }, Cmd.none )

        VideoListReceived (Ok videoList) ->
            let
                authorIDs =
                    videoList.objects
                        |> List.map (\video -> video.profile)
            in
            ( { model | videoData = Data.Kinto.Received videoList }
            , Request.KintoProfile.getProfileList session.kintoURL authorIDs AuthorsFetched
            )

        VideoListReceived (Err error) ->
            ( { model | videoData = Data.Kinto.Failed error }, Cmd.none )

        AuthorsFetched (Ok authors) ->
            ( { model | authorsData = Data.Kinto.Received authors }, Cmd.none )

        AuthorsFetched (Err error) ->
            ( { model | authorsData = Data.Kinto.Failed error }, Cmd.none )

        NewTimestamp timestamp ->
            ( { model | timestamp = timestamp }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view { timezone, staticFiles } ({ title, search, videoData, authorsData, timestamp } as model) =
    ( title
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__banner" ] []
            , H.div [ HA.class "hero__container" ]
                [ H.img
                    [ HA.src staticFiles.logo_ca12
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
            (case videoData of
                Data.Kinto.NotRequested ->
                    []

                Data.Kinto.Requested ->
                    [ H.section [ HA.class "section section-white" ]
                        [ H.div [ HA.class "container" ]
                            [ H.text "Chargement des vidéos..." ]
                        ]
                    ]

                Data.Kinto.Received videoList ->
                    viewVideoList timezone timestamp model videoList

                Data.Kinto.Failed error ->
                    [ H.section [ HA.class "section section-white" ]
                        [ H.div [ HA.class "container" ]
                            [ H.text <| "Erreur lors du chargement des videos: " ++ Kinto.errorToString error ]
                        ]
                    ]
            )
      ]
    )


viewVideoList :
    Time.Zone
    -> Time.Posix
    -> { a | search : String, authorsData : Data.Kinto.KintoData Data.Kinto.ProfileList }
    -> Data.Kinto.VideoList
    -> List (H.Html Msg)
viewVideoList timezone timestamp { search, authorsData } videoList =
    let
        keywordList =
            videoList.objects
                |> List.concatMap (\{ keywords } -> keywords)
                |> Set.fromList
                -- Don't display videos related to the project itself by default
                |> Set.remove "Le projet Classe à 12"
                |> Set.toList
                |> List.sortWith NaturalOrdering.compare

        filteredVideoList =
            if search /= "" then
                videoList.objects
                    |> List.filter (\video -> List.member search video.keywords)

            else
                videoList.objects
                    -- Don't display videos related to the project itself by default
                    |> List.filter (\video -> not <| List.member "Le projet Classe à 12" video.keywords)

        videoCards =
            if filteredVideoList /= [] then
                filteredVideoList
                    |> List.map (\video -> viewPublicVideo timezone timestamp video authorsData)

            else
                [ H.text "Pas de vidéos trouvée" ]
    in
    [ H.section [ HA.class "section section-white" ]
        [ H.div [ HA.class "container" ]
            [ H.div
                [ HA.class "form__group light-background" ]
                [ H.label [ HA.for "search" ]
                    [ H.text "Filtrer :" ]
                , H.div [ HA.class "search__group" ]
                    [ H.select
                        [ HA.id "keywords"
                        , HA.value search
                        , Page.Common.Components.onChange UpdateSearch
                        ]
                        [ Page.Common.Components.optgroup "Afficher :"
                            [ H.option [ HA.value "" ] [ H.text "Toutes les vidéos pédagogiques" ]
                            , H.option [ HA.value "Le projet Classe à 12" ] [ H.text "Les vidéos à propos du projet Classe à 12" ]
                            ]
                        , Page.Common.Components.optgroup "Filtrer les vidéos par mot clé :"
                            (keywordList
                                |> List.map
                                    (\keyword ->
                                        H.option [ HA.value keyword ] [ H.text keyword ]
                                    )
                            )
                        ]
                    , if search /= "" then
                        H.button
                            [ HA.class "button-link"
                            , HE.onClick <| UpdateSearch ""
                            ]
                            [ H.i [ HA.class "fas fa-times" ] [] ]

                      else
                        H.div [] []
                    ]
                ]
            ]
        ]
    , H.section [ HA.class "section section-grey cards" ]
        [ H.div [ HA.class "container" ]
            [ H.div [ HA.class "row" ]
                videoCards
            ]
        ]
    ]


viewPublicVideo : Time.Zone -> Time.Posix -> Data.Kinto.Video -> Data.Kinto.KintoData Data.Kinto.ProfileList -> H.Html msg
viewPublicVideo timezone timestamp video authorsData =
    let
        isVideoRecent =
            let
                timestampMillis =
                    Time.posixToMillis timestamp

                publishDateMillis =
                    Time.posixToMillis video.publish_date
            in
            if timestampMillis == 0 then
                -- The timestamp isn't initialized yet
                False

            else
                timestampMillis
                    - publishDateMillis
                    -- A video is recent if it's less than 15 days.
                    |> (>) (15 * 24 * 60 * 60 * 1000)

        profileData =
            case authorsData of
                Data.Kinto.Received authors ->
                    authors.objects
                        |> List.filter (\author -> author.id == video.profile)
                        |> List.head
                        |> Maybe.map Data.Kinto.Received
                        |> Maybe.withDefault Data.Kinto.NotRequested

                _ ->
                    Data.Kinto.NotRequested
    in
    H.a
        [ HA.class "card"
        , Route.href <| Route.Video video.id video.title
        ]
        [ H.div
            [ HA.class "card__cover" ]
            [ H.div
                [ HA.class "new-video"
                , HA.style "display" <|
                    if isVideoRecent then
                        "block"

                    else
                        "none"
                ]
                [ H.text "Nouveauté !" ]
            , H.img
                [ HA.alt video.title
                , HA.src video.thumbnail
                ]
                []
            ]
        , Page.Common.Video.details timezone video profileData
        , Page.Common.Video.keywords video
        ]

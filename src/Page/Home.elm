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
view session ({ search } as model) =
    ( "Liste des vidéos"
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__banner" ] []
            , H.div [ HA.class "hero__container" ]
                [ H.img
                    [ HA.src "./logo_ca12.png"
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
                            [ H.text "Cherchez un titre de vidéo :" ]
                        , H.div [ HA.class "search__group" ]
                            [ H.input
                                [ HA.id "search"
                                , HA.type_ "search"
                                , HA.placeholder "produire une vidéo"
                                , HA.value search
                                , HE.onInput UpdateSearch
                                ]
                                []
                            , H.button [ HA.class "overlay-button" ]
                                [ H.i [ HA.class "fa fa-search" ] [] ]
                            ]
                        ]
                    ]
                ]
            , H.section [ HA.class "section section-grey cards" ]
                [ H.div [ HA.class "container" ]
                    (case session.videoData of
                        Fetching ->
                            [ H.text "Chargement des vidéos..." ]

                        Received videoList ->
                            viewVideoList model videoList

                        Error error ->
                            [ H.text <| "Erreur lors du chargement des videos: " ++ error ]
                    )
                ]
            ]
      ]
    )


viewVideoList : { a | activeVideo : Maybe Data.Session.Video, search : String } -> List Data.Session.Video -> List (H.Html Msg)
viewVideoList ({ search } as model) videoList =
    let
        filteredVideoList =
            videoList
                |> List.filter (\video -> String.contains search video.title)
    in
    [ H.div [ HA.class "row" ]
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
    H.div
        [ HA.class "card" ]
        [ H.div
            [ HA.classList
                [ ( "modal__backdrop", True )
                , ( "is-active", active )
                ]
            , HE.onClick HideVideo
            ]
            [ H.div [ HA.class "modal" ]
                [ H.iframe
                    [ HA.src video.player
                    , HA.title "Partie 2 : am&eacute;nager sa classe pour co-enseigner."
                    , stringProperty "scrolling" "no"
                    , stringProperty "frameborder" "0"
                    , stringProperty "allowfullscreen" "true"
                    ]
                    []
                ]
            , H.button [ HA.class "modal__close" ]
                [ H.i [ HA.class "fa fa-times fa-2x" ] [] ]
            ]
        , H.div
            [ HA.class "card__cover"
            , HE.onClick <| ShowVideo video
            ]
            [ H.img
                [ HA.src video.thumbnail
                , HA.alt <| "Thumbnail of the video titled: " ++ video.title
                ]
                []
            ]
        , H.div
            [ HA.class "card__content"
            , HE.onClick <| ShowVideo video
            ]
            [ H.h3 [] [ H.text video.title ]
            , H.div [ HA.class "card__meta" ]
                [ H.time [] [ H.text video.pubDate ]
                ]
            ]
        ]


stringProperty : String -> String -> H.Attribute msg
stringProperty name value =
    HA.property name <| Encode.string value

module Page.Participate exposing (Model, Msg(..), init, update, view)

import Data.Kinto exposing (KintoData(..))
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Kinto
import Request.KintoUpcoming


type alias Model =
    { newVideo : Data.Session.Video
    , newVideoKintoData : KintoData Data.Session.Video
    , error : Maybe String
    }


emptyVideo =
    { description = ""
    , link = ""
    , player = ""
    , pubDate = ""
    , thumbnail = ""
    , title = ""
    }


type Msg
    = UpdateVideoForm Data.Session.Video
    | SubmitNewVideo
    | NewVideoSubmitted (Result Kinto.Error Data.Session.Video)
    | DiscardError


init : Session -> ( Model, Cmd Msg )
init session =
    ( { newVideo = emptyVideo
      , newVideoKintoData = NotRequested
      , error = Nothing
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        UpdateVideoForm video ->
            ( { model | newVideo = video }, Cmd.none )

        SubmitNewVideo ->
            ( { model | newVideoKintoData = Requested }
            , Request.KintoUpcoming.submitVideo model.newVideo NewVideoSubmitted
            )

        NewVideoSubmitted (Ok video) ->
            ( { model
                | newVideo = emptyVideo
                , newVideoKintoData = NotRequested
              }
            , Cmd.none
            )

        NewVideoSubmitted (Err error) ->
            ( { model
                | newVideoKintoData = NotRequested
                , error = Just <| Kinto.errorToString error
              }
            , Cmd.none
            )

        DiscardError ->
            ( { model | error = Nothing }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view _ { newVideo, newVideoKintoData, error } =
    ( "Je participe !"
    , [ H.div []
            [ displayError error
            , H.text "Vous aimeriez avoir l'avis de vos collègues sur une problématique ou souhaitez poster une vidéo pour aider le collectif, contactez-nous !"
            , H.form [ HE.onSubmit SubmitNewVideo ]
                [ H.div [ HA.class "field is-horizontal" ]
                    [ H.div [ HA.class "field-label is-normal" ]
                        [ H.label [ HA.class "label", HA.for "title" ]
                            [ H.text "Titre" ]
                        ]
                    , H.div [ HA.class "field-body" ]
                        [ H.div [ HA.class "field" ]
                            [ H.div [ HA.class "control" ]
                                [ H.input
                                    [ HA.class "input"
                                    , HA.type_ "text"
                                    , HA.id "title"
                                    , HA.placeholder "Titre de la vidéo"
                                    , HA.value newVideo.title
                                    , HE.onInput <| \title -> UpdateVideoForm { newVideo | title = title }
                                    ]
                                    []
                                ]
                            ]
                        ]
                    ]
                , H.div [ HA.class "field is-horizontal" ]
                    [ H.div [ HA.class "field-label is-normal" ]
                        [ H.label [ HA.class "label", HA.for "link" ]
                            [ H.text "Lien vers la vidéo" ]
                        ]
                    , H.div [ HA.class "field-body" ]
                        [ H.div [ HA.class "field" ]
                            [ H.div [ HA.class "control" ]
                                [ H.input
                                    [ HA.class "input"
                                    , HA.type_ "text"
                                    , HA.id "link"
                                    , HA.placeholder "https://example.com/mavideo"
                                    , HA.value newVideo.link
                                    , HE.onInput <| \link -> UpdateVideoForm { newVideo | link = link }
                                    ]
                                    []
                                ]
                            ]
                        ]
                    ]
                , H.div [ HA.class "field is-horizontal" ]
                    [ H.div [ HA.class "field-label is-normal" ]
                        [ H.label [ HA.class "label", HA.for "thumbnail" ]
                            [ H.text "Lien vers la miniature de la vidéo" ]
                        ]
                    , H.div [ HA.class "field-body" ]
                        [ H.div [ HA.class "field" ]
                            [ H.div [ HA.class "control" ]
                                [ H.input
                                    [ HA.class "input"
                                    , HA.type_ "text"
                                    , HA.id "thumbnail"
                                    , HA.placeholder "https://example.com/mavideo.png"
                                    , HA.value newVideo.thumbnail
                                    , HE.onInput <| \thumbnail -> UpdateVideoForm { newVideo | thumbnail = thumbnail }
                                    ]
                                    []
                                ]
                            ]
                        ]
                    ]
                , H.div [ HA.class "field is-horizontal" ]
                    [ H.div [ HA.class "field-label is-normal" ]
                        [ H.label [ HA.class "label", HA.for "pubDate" ]
                            [ H.text "Date de la vidéo" ]
                        ]
                    , H.div [ HA.class "field-body" ]
                        [ H.div [ HA.class "field" ]
                            [ H.div [ HA.class "control" ]
                                [ H.input
                                    [ HA.class "input"
                                    , HA.type_ "text"
                                    , HA.id "pubDate"
                                    , HA.placeholder "2018-10-12"
                                    , HA.value newVideo.pubDate
                                    , HE.onInput <| \pubDate -> UpdateVideoForm { newVideo | pubDate = pubDate }
                                    ]
                                    []
                                ]
                            ]
                        ]
                    ]
                , H.div [ HA.class "field is-horizontal" ]
                    [ H.div [ HA.class "field-label is-normal" ]
                        [ H.label [ HA.class "label", HA.for "player" ]
                            [ H.text "Lien vers le player de la vidéo" ]
                        ]
                    , H.div [ HA.class "field-body" ]
                        [ H.div [ HA.class "field" ]
                            [ H.div [ HA.class "control" ]
                                [ H.input
                                    [ HA.class "input"
                                    , HA.type_ "text"
                                    , HA.id "player"
                                    , HA.placeholder "https://player.example.com/mavideo"
                                    , HA.value newVideo.player
                                    , HE.onInput <| \player -> UpdateVideoForm { newVideo | player = player }
                                    ]
                                    []
                                ]
                            ]
                        ]
                    ]
                , H.div [ HA.class "field is-horizontal" ]
                    [ H.div [ HA.class "field-label is-normal" ]
                        [ H.label [ HA.class "label", HA.for "description" ]
                            [ H.text "Description" ]
                        ]
                    , H.div [ HA.class "field-body" ]
                        [ H.div [ HA.class "field" ]
                            [ H.div [ HA.class "control" ]
                                [ H.textarea
                                    [ HA.class "textarea"
                                    , HA.id "description"
                                    , HA.placeholder "Description : que montre la vidéo ?"
                                    , HA.value newVideo.description
                                    , HE.onInput <| \description -> UpdateVideoForm { newVideo | description = description }
                                    ]
                                    []
                                ]
                            ]
                        ]
                    ]
                , H.div [ HA.class "field is-horizontal" ]
                    [ H.div [ HA.class "control" ]
                        [ loadingButton "Soumettre cette vidéo" newVideoKintoData ]
                    ]
                ]
            ]
      ]
    )


displayError : Maybe String -> H.Html Msg
displayError maybeError =
    case maybeError of
        Just error ->
            H.div [ HA.class "notification is-danger" ]
                [ H.button
                    [ HA.class "delete"
                    , HE.onClick DiscardError
                    ]
                    []
                , H.text error
                ]

        Nothing ->
            H.div [] []


loadingButton : String -> KintoData Data.Session.Video -> H.Html Msg
loadingButton label dataState =
    let
        loading =
            dataState == Requested
    in
    H.button
        [ HA.type_ "submit"
        , HA.classList
            [ ( "button is-primary", True )
            , ( "is-loading", loading )
            ]
        , HA.disabled loading
        ]
        [ H.text label ]
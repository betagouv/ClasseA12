module Page.Participate exposing (Model, Msg(..), init, update, view)

import Data.Kinto exposing (KintoData(..), Video, emptyVideo)
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode
import Kinto
import Ports
import Request.KintoUpcoming


type alias Model =
    { newVideo : Video
    , newVideoKintoData : KintoData Video
    , videoObjectUrl : Maybe String
    , error : Maybe String
    }


type Msg
    = UpdateVideoForm Video
    | SubmitNewVideo
    | NewVideoSubmitted (Result Kinto.Error Video)
    | DiscardError
    | VideoSelected
    | VideoObjectUrlReceived Decode.Value
    | AttachmentSent Decode.Value


init : Session -> ( Model, Cmd Msg )
init session =
    ( { newVideo = emptyVideo
      , newVideoKintoData = NotRequested
      , videoObjectUrl = Nothing
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
            ( model, Ports.submitVideo ( "video", video.id ) )

        NewVideoSubmitted (Err error) ->
            ( { model
                | newVideoKintoData = NotRequested
                , error = Just <| Kinto.errorToString error
              }
            , Cmd.none
            )

        DiscardError ->
            ( { model | error = Nothing }, Cmd.none )

        VideoSelected ->
            ( model, Ports.videoSelected "video" )

        VideoObjectUrlReceived value ->
            let
                objectUrl =
                    Decode.decodeValue Decode.string value
            in
            ( { model | videoObjectUrl = Result.toMaybe objectUrl }, Cmd.none )

        AttachmentSent _ ->
            ( { model
                | newVideo = emptyVideo
                , newVideoKintoData = NotRequested
                , videoObjectUrl = Nothing
              }
            , Cmd.none
            )


view : Session -> Model -> ( String, List (H.Html Msg) )
view _ { newVideo, newVideoKintoData, videoObjectUrl, error } =
    ( "Je participe !"
    , [ H.div []
            [ displayError error
            , H.text "Vous aimeriez avoir l'avis de vos collègues sur une problématique ou souhaitez poster une vidéo pour aider le collectif, contactez-nous !"
            , displayVideo videoObjectUrl
            , H.form [ HE.onSubmit SubmitNewVideo ]
                [ H.div [ HA.class "field" ]
                    [ H.div [ HA.class "file is-primary is-boxed is-large is-centered" ]
                        [ H.div [ HA.class "file-label" ]
                            [ H.label [ HA.class "label" ]
                                [ H.input
                                    [ HA.class "file-input"
                                    , HA.type_ "file"
                                    , HA.id "video"
                                    , HA.accept "video/*"
                                    , onFileSelected VideoSelected
                                    ]
                                    []
                                , H.span [ HA.class "file-cta" ]
                                    [ H.span [ HA.class "file-icon" ]
                                        [ H.i [ HA.class "fa fa-upload" ] []
                                        ]
                                    , H.span [ HA.class "file-label" ] [ H.text "Fichier vidéo" ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                , formInput
                    H.input
                    "title"
                    "Titre"
                    "Titre de la video"
                    newVideo.title
                    (\title -> UpdateVideoForm { newVideo | title = title })
                , formInput
                    H.input
                    "keywords"
                    "Mots Clés"
                    "Lecture, Mathématiques ..."
                    newVideo.keywords
                    (\keywords -> UpdateVideoForm { newVideo | keywords = keywords })
                , formInput
                    H.textarea
                    "description"
                    "Description"
                    "Description : que montre la vidéo ?"
                    newVideo.description
                    (\description -> UpdateVideoForm { newVideo | description = description })
                , H.div [ HA.class "field is-horizontal" ]
                    [ H.div [ HA.class "control" ]
                        [ loadingButton "Soumettre cette vidéo" newVideoKintoData ]
                    ]
                ]
            ]
      ]
    )


displayVideo : Maybe String -> H.Html Msg
displayVideo maybeVideoObjectUrl =
    case maybeVideoObjectUrl of
        Just videoObjectUrl ->
            H.div []
                [ H.video
                    [ HA.src videoObjectUrl
                    , HA.controls True
                    ]
                    []
                ]

        Nothing ->
            H.div [] []


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


type alias HtmlNode msg =
    List (H.Attribute msg) -> List (H.Html msg) -> H.Html msg


formInput : HtmlNode msg -> String -> String -> String -> String -> (String -> msg) -> H.Html msg
formInput input id label placeholder value onInput =
    H.div [ HA.class "field is-horizontal" ]
        [ H.div [ HA.class "field-label is-normal" ]
            [ H.label [ HA.class "label", HA.for id ]
                [ H.text label ]
            ]
        , H.div [ HA.class "field-body" ]
            [ H.div [ HA.class "field" ]
                [ H.div [ HA.class "control" ]
                    [ input
                        [ HA.class <|
                            -- UGLY : special casing the textarea class, this thing is very weird in the Bulma css framework.
                            if id == "description" then
                                "textarea"

                            else
                                "input"
                        , HA.id id
                        , HA.placeholder placeholder
                        , HA.value value
                        , HE.onInput onInput
                        ]
                        []
                    ]
                ]
            ]
        ]


loadingButton : String -> KintoData Video -> H.Html Msg
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


onFileSelected msg =
    HE.on "change" (Decode.succeed VideoSelected)

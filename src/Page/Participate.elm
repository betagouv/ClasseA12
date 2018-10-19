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
    }


type Msg
    = UpdateVideoForm Video
    | SubmitNewVideo
    | NewVideoSubmitted (Result Kinto.Error Video)
    | DiscardNotification
    | VideoSelected
    | VideoObjectUrlReceived Decode.Value
    | AttachmentSent Decode.Value


init : Session -> ( Model, Cmd Msg )
init session =
    ( { newVideo = emptyVideo
      , newVideoKintoData = NotRequested
      , videoObjectUrl = Nothing
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
            ( { model | newVideoKintoData = Failed error }
            , Cmd.none
            )

        DiscardNotification ->
            ( { model | newVideoKintoData = NotRequested }, Cmd.none )

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
                , newVideoKintoData = Received model.newVideo
                , videoObjectUrl = Nothing
              }
            , Cmd.none
            )


view : Session -> Model -> ( String, List (H.Html Msg) )
view _ model =
    ( "Je participe !"
    , [ H.div []
            [ displayKintoData model.newVideoKintoData
            , H.text "Vous aimeriez avoir l'avis de vos collègues sur une problématique ou souhaitez poster une vidéo pour aider le collectif, vous êtes au bon endroit !"
            , displaySubmitVideoForm model
            ]
      ]
    )


displaySubmitVideoForm : { a | newVideo : Video, newVideoKintoData : KintoData Video, videoObjectUrl : Maybe String } -> H.Html Msg
displaySubmitVideoForm { newVideo, newVideoKintoData, videoObjectUrl } =
    let
        videoSelected =
            videoObjectUrl
                /= Nothing
    in
    H.form [ HE.onSubmit SubmitNewVideo ]
        [ H.div [ HA.class "field" ]
            [ H.div
                [ HA.class "file is-primary is-boxed is-large is-centered"
                ]
                [ displayVideo videoObjectUrl
                , H.div
                    [ HA.class "file-label"
                    , HA.style "display"
                        (if videoSelected then
                            "none"

                         else
                            "block"
                        )
                    ]
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
                            , H.span [ HA.class "file-label" ] [ H.text "Envoyer un fichier vidéo" ]
                            ]
                        ]
                    ]
                ]
            ]
        , formInput
            H.input
            "title"
            "Titre*"
            "Titre de la video"
            newVideo.title
            (\title -> UpdateVideoForm { newVideo | title = title })
            videoSelected
        , formInput
            H.textarea
            "description"
            "Description"
            "Description : que montre la vidéo ?"
            newVideo.description
            (\description -> UpdateVideoForm { newVideo | description = description })
            videoSelected
        , formInput
            H.input
            "keywords"
            "Mots Clés"
            "Coin lecture, organisation de la classe, trucs et astuces, ..."
            newVideo.keywords
            (\keywords -> UpdateVideoForm { newVideo | keywords = keywords })
            videoSelected
        , H.div
            [ HA.class "field is-horizontal"
            , HA.style "display"
                (if videoSelected then
                    "block"

                 else
                    "none"
                )
            ]
            [ H.div [ HA.class "control" ]
                [ H.button
                    [ HA.type_ "submit"
                    , HA.class "button is-primary"
                    , HA.disabled (newVideo.title == "")
                    ]
                    [ H.text "Soumettre cette vidéo" ]
                ]
            ]
        , H.div
            [ HA.classList
                [ ( "modal", True )
                , ( "is-active", newVideoKintoData == Requested )
                ]
            ]
            [ H.div [ HA.class "modal-background" ] []
            , H.div [ HA.class "modal-card" ]
                [ H.div [ HA.class "modal-card" ]
                    [ H.header [ HA.class "modal-card-head" ]
                        [ H.p [ HA.class "modal-card-title" ] [ H.text "Envoi de la vidéo en cours" ]
                        ]
                    , H.section [ HA.class "modal-card-body" ]
                        [ H.text "Veuillez patienter..."
                        , H.p
                            [ HA.style "font-size" "10em"
                            , HA.style "text-align" "center"
                            ]
                            [ H.span [ HA.class "icon" ]
                                [ H.i [ HA.class "fa fa-spinner fa-spin" ] [] ]
                            ]
                        ]
                    , H.footer [ HA.class "modal-card-foot" ]
                        []
                    ]
                ]
            ]
        ]


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


displayKintoData : KintoData Video -> H.Html Msg
displayKintoData kintoData =
    case kintoData of
        Failed error ->
            H.div [ HA.class "notification is-danger" ]
                [ H.button
                    [ HA.class "delete"
                    , HE.onClick DiscardNotification
                    ]
                    []
                , H.text <| Kinto.errorToString error
                ]

        Received _ ->
            H.div [ HA.class "notification is-success" ]
                [ H.button
                    [ HA.class "delete"
                    , HE.onClick DiscardNotification
                    ]
                    []
                , H.text "Merci pour cette vidéo ! Vous pouvez en poster une autre ou "
                , H.a [ HA.src "#/" ] [ H.text "retourner à la liste de vidéos" ]
                ]

        _ ->
            H.div [] []


type alias HtmlNode msg =
    List (H.Attribute msg) -> List (H.Html msg) -> H.Html msg


formInput : HtmlNode msg -> String -> String -> String -> String -> (String -> msg) -> Bool -> H.Html msg
formInput input id label placeholder value onInput isVisible =
    H.div
        [ HA.class "field is-horizontal"
        , HA.style "display"
            (if isVisible then
                "flex"

             else
                "none"
            )
        ]
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


onFileSelected msg =
    HE.on "change" (Decode.succeed VideoSelected)

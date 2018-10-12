module Page.Participate exposing (Model, Msg(..), init, update, view)

import Data.Kinto exposing (KintoData(..))
import Data.Session exposing (Session, Video)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Kinto
import Request.KintoUpcoming


type alias Model =
    { newVideo : Video
    , newVideoKintoData : KintoData Video
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
    = UpdateVideoForm Video
    | SubmitNewVideo
    | NewVideoSubmitted (Result Kinto.Error Video)
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
                [ formInput
                    H.input
                    "title"
                    "Titre"
                    "Titre de la video"
                    newVideo.title
                    (\title -> UpdateVideoForm { newVideo | title = title })
                , formInput
                    H.input
                    "link"
                    "Lien vers la vidéo"
                    "https://example.com/mavideo"
                    newVideo.link
                    (\link -> UpdateVideoForm { newVideo | link = link })
                , formInput
                    H.input
                    "thumbnail"
                    "Lien vers la miniature de la vidéo"
                    "https://example.com/mavideo.png"
                    newVideo.thumbnail
                    (\thumbnail -> UpdateVideoForm { newVideo | thumbnail = thumbnail })
                , formInput
                    H.input
                    "pubDate"
                    "Date de la vidéo"
                    "2018-10-12"
                    newVideo.pubDate
                    (\pubDate -> UpdateVideoForm { newVideo | pubDate = pubDate })
                , formInput
                    H.input
                    "player"
                    "Lien vers le player de la vidéo"
                    "https://player.example.com/mavideo"
                    newVideo.player
                    (\player -> UpdateVideoForm { newVideo | player = player })
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

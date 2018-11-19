module Page.Participate exposing (Model, Msg(..), init, update, view)

import Data.Kinto exposing (KintoData(..), Video, emptyVideo)
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Decode as Decode
import Kinto
import Ports
import Random
import Random.Char
import Random.String
import Request.KintoUpcoming
import Route


type alias Model =
    { newVideo : Video
    , newVideoKintoData : KintoData Video
    , videoObjectUrl : Maybe String
    , percentage : Int
    , approved : Bool
    , displayCGU : Bool
    }


type Credentials
    = Credentials ( String, String )


type Msg
    = UpdateVideoForm Video
    | GenerateRandomCredentials
    | SubmitNewVideo Credentials
    | DiscardNotification
    | VideoSelected
    | VideoObjectUrlReceived Decode.Value
    | ProgressUpdated Decode.Value
    | AttachmentSent String
    | OnApproved Bool
    | DisplayCGU
    | DiscardCGU


init : Session -> ( Model, Cmd Msg )
init session =
    ( { newVideo = emptyVideo
      , newVideoKintoData = NotRequested
      , videoObjectUrl = Nothing
      , percentage = 0
      , approved = False
      , displayCGU = False
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        UpdateVideoForm video ->
            ( { model | newVideo = video }, Cmd.none )

        GenerateRandomCredentials ->
            -- TODO : this is only there temporarily, and will be replaced by the user's credentials
            ( model, generateRandomCredentials )

        SubmitNewVideo (Credentials ( login, password )) ->
            let
                submitVideoData : Ports.SubmitVideoData
                submitVideoData =
                    { nodeID = "video"
                    , videoData = Data.Kinto.encodeVideoData model.newVideo
                    , login = login
                    , password = password
                    }
            in
            ( { model | newVideoKintoData = Requested }
            , Ports.submitVideo submitVideoData
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

        ProgressUpdated value ->
            let
                percentage =
                    Decode.decodeValue Decode.int value
                        |> Result.toMaybe
                        |> Maybe.withDefault 0
            in
            ( { model | percentage = percentage }, Cmd.none )

        AttachmentSent response ->
            let
                result =
                    Decode.decodeString Data.Kinto.attachmentDecoder response
                        |> Result.mapError
                            (\_ ->
                                Decode.decodeString Kinto.errorDecoder response
                                    |> Result.map
                                        (\errorDetail ->
                                            Kinto.KintoError errorDetail.code errorDetail.message errorDetail
                                        )
                                    |> Result.withDefault (Kinto.NetworkError Http.NetworkError)
                            )

                kintoData =
                    case result of
                        Ok video ->
                            Received model.newVideo

                        Err error ->
                            Failed error
            in
            ( { model
                | newVideo = emptyVideo
                , newVideoKintoData = kintoData
                , videoObjectUrl = Nothing
                , percentage = 0
              }
            , Cmd.none
            )

        OnApproved approved ->
            ( { model | approved = approved }, Cmd.none )

        DisplayCGU ->
            ( { model | displayCGU = True }, Cmd.none )

        DiscardCGU ->
            ( { model | displayCGU = False }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view _ model =
    ( "Je participe !"
    , [ H.div [ HA.class "main" ]
            [ H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ displayKintoData model.newVideoKintoData
                    , H.p [] [ H.text "Vous aimeriez avoir l'avis de vos collègues sur une problématique ou souhaitez poster une vidéo pour aider le collectif, vous êtes au bon endroit !" ]
                    , H.p []
                        [ H.text "L'utilisation de ce service est régi par une "
                        , H.a
                            [ Route.href Route.CGU
                            , HE.onClick DisplayCGU
                            ]
                            [ H.text "charte de bonne conduite" ]
                        , H.text "."
                        ]
                    , displaySubmitVideoForm model
                    ]
                ]
            ]
      ]
    )


displaySubmitVideoForm :
    { a
        | newVideo : Video
        , newVideoKintoData : KintoData Video
        , videoObjectUrl : Maybe String
        , percentage : Int
        , approved : Bool
    }
    -> H.Html Msg
displaySubmitVideoForm { newVideo, newVideoKintoData, videoObjectUrl, percentage, approved } =
    let
        videoSelected =
            videoObjectUrl
                /= Nothing
    in
    H.form [ HE.onSubmit GenerateRandomCredentials ]
        [ H.div
            [ HA.class "upload-video"
            ]
            [ displayVideo videoObjectUrl
            , H.label
                [ HA.style "display"
                    (if videoSelected then
                        "none"

                     else
                        "block"
                    )
                ]
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
            [ HA.class "form__group"
            , HA.style "display"
                (if videoSelected then
                    "block"

                 else
                    "none"
                )
            ]
            [ H.input
                [ HA.id "approve_CGU"
                , HA.type_ "checkbox"
                , HA.checked approved
                , HE.onCheck OnApproved
                ]
                []
            , H.label [ HA.for "approveCGU", HA.class "label-inline" ]
                [ H.text "J'ai lu et j'accepte d'adhérer à la charte de bonne conduite" ]
            ]
        , H.button
            [ HA.type_ "submit"
            , HA.class "button"
            , HA.disabled (newVideo.title == "" || not approved)
            , HA.style "display"
                (if videoSelected then
                    "block"

                 else
                    "none"
                )
            ]
            [ H.text "Soumettre cette vidéo" ]
        , H.div
            [ HA.classList
                [ ( "modal__backdrop", True )
                , ( "is-active", newVideoKintoData == Requested )
                ]
            ]
            [ H.div [ HA.class "modal" ]
                [ H.h1 [] [ H.text "Envoi de la vidéo en cours, veuillez patienter..." ]
                , H.progress
                    [ HA.class "is-large"
                    , HA.value <| String.fromInt percentage
                    , HA.max "100"
                    ]
                    [ H.text <| String.fromInt percentage ++ "%" ]
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
            H.div [ HA.class "notification error closable" ]
                [ H.button
                    [ HA.class "close"
                    , HE.onClick DiscardNotification
                    ]
                    [ H.i [ HA.class "fa fa-times" ] [] ]
                , H.text <| Kinto.errorToString error
                ]

        Received _ ->
            H.div [ HA.class "notification success closable" ]
                [ H.button
                    [ HA.class "close"
                    , HE.onClick DiscardNotification
                    ]
                    [ H.i [ HA.class "fa fa-times" ] [] ]
                , H.text "Merci pour cette vidéo ! Vous pouvez en poster une autre ou "
                , H.a [ Route.href Route.Home ] [ H.text "retourner à la liste de vidéos" ]
                ]

        _ ->
            H.div [] []


type alias HtmlNode msg =
    List (H.Attribute msg) -> List (H.Html msg) -> H.Html msg


formInput : HtmlNode msg -> String -> String -> String -> String -> (String -> msg) -> Bool -> H.Html msg
formInput input id label placeholder value onInput isVisible =
    H.div
        [ HA.class "form__group"
        , HA.style "display"
            (if isVisible then
                "block"

             else
                "none"
            )
        ]
        [ H.label [ HA.for id ]
            [ H.text label ]
        , input
            [ HA.id id
            , HA.placeholder placeholder
            , HA.value value
            , HE.onInput onInput
            ]
            []
        ]


onFileSelected msg =
    HE.on "change" (Decode.succeed VideoSelected)


randomString : Random.Generator String
randomString =
    Random.String.string 20 Random.Char.latin


stringPair : Random.Generator ( String, String )
stringPair =
    Random.pair randomString randomString


generateRandomCredentials : Cmd Msg
generateRandomCredentials =
    Random.generate
        SubmitNewVideo
        (stringPair
            |> Random.map Credentials
        )

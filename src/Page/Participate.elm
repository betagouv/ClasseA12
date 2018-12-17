module Page.Participate exposing (Model, Msg(..), init, update, view)

import Data.Kinto exposing (KintoData(..), NewVideo, Video, emptyNewVideo, emptyVideo)
import Data.Session exposing (Session)
import Dict
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Kinto
import Page.Utils
import Ports
import Random
import Random.Char
import Random.String
import Request.KintoUpcoming
import Route
import Task
import Time


type alias Model =
    { newVideo : NewVideo
    , newVideoKintoData : KintoData Video
    , videoObjectUrl : Maybe String
    , progress : Progress
    , approved : Bool
    , displayCGU : Bool
    }


type alias Progress =
    { percentage : Int
    , message : String
    }


emptyProgress : Progress
emptyProgress =
    { percentage = 0, message = "" }


type Credentials
    = Credentials ( String, String )


type Msg
    = UpdateVideoForm NewVideo
    | GetTimestamp
    | GenerateRandomCredentials Time.Posix
    | SubmitNewVideo Time.Posix Credentials
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
    ( { newVideo = emptyNewVideo
      , newVideoKintoData = NotRequested
      , videoObjectUrl = Nothing
      , progress = emptyProgress
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

        GetTimestamp ->
            ( model, Task.perform GenerateRandomCredentials Time.now )

        GenerateRandomCredentials timestamp ->
            -- TODO : this is only there temporarily, and will be replaced by the user's credentials
            ( model, generateRandomCredentials timestamp )

        SubmitNewVideo timestamp (Credentials ( login, password )) ->
            let
                newVideo =
                    model.newVideo

                newVideoWithCreationDate =
                    { newVideo | creation_date = timestamp }

                submitVideoData : Ports.SubmitVideoData
                submitVideoData =
                    { nodeID = "video"
                    , videoNodeID = "uploaded-video"
                    , videoData = Data.Kinto.encodeNewVideoData newVideoWithCreationDate
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
                progressDecoder =
                    Decode.succeed Progress
                        |> Pipeline.required "percentage" Decode.int
                        |> Pipeline.required "message" Decode.string

                progress =
                    Decode.decodeValue progressDecoder value
                        |> Result.withDefault emptyProgress
            in
            ( { model | progress = progress }, Cmd.none )

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
                        Ok attachment ->
                            let
                                video =
                                    { emptyVideo
                                        | title = model.newVideo.title
                                        , keywords = model.newVideo.keywords
                                        , description = model.newVideo.description
                                        , attachment = attachment
                                    }
                            in
                            Received video

                        Err error ->
                            Failed error
            in
            ( { model
                | newVideo = emptyNewVideo
                , newVideoKintoData = kintoData
                , videoObjectUrl = Nothing
                , progress = emptyProgress
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
                            [ Route.href Route.Convention ]
                            [ H.text "charte de bonne conduite" ]
                        , H.text " et des "
                        , H.a
                            [ Route.href Route.CGU ]
                            [ H.text "conditions générales d'utilisation" ]
                        , H.text "."
                        ]
                    , H.p []
                        [ H.text "Pensez bien à faire signer les autorisations de droit à l'image !"
                        , H.ul []
                            [ H.li []
                                [ H.a [ HA.href "/documents/Autorisation-captation-image-mineur_2017.pdf" ]
                                    [ H.text "Autorisation-captation-image-mineur_2017.pdf" ]
                                ]
                            , H.li []
                                [ H.a [ HA.href "/documents/Autorisation-captation-image-majeur_2017.pdf" ]
                                    [ H.text "Autorisation-captation-image-majeur_2017.pdf" ]
                                ]
                            ]
                        ]
                    , displaySubmitVideoForm model
                    ]
                ]
            ]
      ]
    )


displaySubmitVideoForm :
    { a
        | newVideo : NewVideo
        , newVideoKintoData : KintoData Video
        , videoObjectUrl : Maybe String
        , progress : Progress
        , approved : Bool
    }
    -> H.Html Msg
displaySubmitVideoForm { newVideo, newVideoKintoData, videoObjectUrl, progress, approved } =
    let
        videoSelected =
            videoObjectUrl
                /= Nothing
    in
    H.form [ HE.onSubmit GetTimestamp ]
        [ displayVideo videoObjectUrl
        , H.div
            [ HA.class "upload-video"
            ]
            [ H.label
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
        , H.div
            [ HA.class "form__group"
            , HA.style "display"
                (if videoSelected then
                    "block"

                 else
                    "none"
                )
            ]
            [ H.fieldset []
                [ H.legend []
                    [ H.text "Niveau" ]
                , H.input
                    [ HA.id "grade-cp"
                    , HA.type_ "radio"
                    , HA.name "grade"
                    , HA.checked <| newVideo.grade == "CP"
                    , HE.onInput (\grade -> UpdateVideoForm { newVideo | grade = "CP" })
                    ]
                    []
                , H.label [ HA.for "grade-cp", HA.class "label-inline" ]
                    [ H.text "CP" ]
                , H.input
                    [ HA.id "grade-ce1"
                    , HA.type_ "radio"
                    , HA.name "grade"
                    , HA.checked <| newVideo.grade == "CE1"
                    , HE.onInput (\grade -> UpdateVideoForm { newVideo | grade = "CE1" })
                    ]
                    []
                , H.label [ HA.for "grade-ce1", HA.class "label-inline" ]
                    [ H.text "CE1" ]
                ]
            ]
        , formInput
            H.textarea
            "description"
            "Description"
            "Description succincte, ville, académie (mise en forme possible avec Markdown)"
            newVideo.description
            (\description -> UpdateVideoForm { newVideo | description = description })
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
            [ H.fieldset []
                ([ H.legend [] [ H.text "Mots Clés" ] ]
                    ++ viewKeywords
                        newVideo.keywords
                        (\keyword -> UpdateVideoForm { newVideo | keywords = Data.Kinto.toggleKeyword keyword newVideo.keywords })
                )
            ]
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
                , H.p [] [ H.text progress.message ]
                , H.progress
                    [ HA.class "is-large"
                    , HA.value <| String.fromInt progress.percentage
                    , HA.max "100"
                    ]
                    [ H.text <| String.fromInt progress.percentage ++ "%" ]
                ]
            ]
        ]


displayVideo : Maybe String -> H.Html Msg
displayVideo maybeVideoObjectUrl =
    H.div [ HA.style "display" "none", HA.style "text-align" "center" ]
        [ H.video
            [ HA.controls True
            , HA.id "uploaded-video"
            ]
            []
        , H.p [] [ H.text "Aperçu de la miniature de la vidéo (déplacer le curseur de la vidéo ci-dessus)" ]
        , H.canvas [ HA.id "thumbnail-preview" ] []
        ]


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


generateRandomCredentials : Time.Posix -> Cmd Msg
generateRandomCredentials timestamp =
    Random.generate
        (SubmitNewVideo timestamp)
        (stringPair
            |> Random.map Credentials
        )


onSelectMultiple : (List String -> Msg) -> H.Attribute Msg
onSelectMultiple tagger =
    HE.on "change" (Decode.map tagger targetSelectedOptions)


checkbox : (String -> Msg) -> (String, Bool) -> List (H.Html Msg)
checkbox msg (key, value) =
    let
        id =
            "keyword-" ++ key
    in
    [ H.input
        [ HA.type_ "checkbox"
        , HA.id id
        , HA.checked value
        , HE.onClick <| msg key
        ]
        []
    , H.label [ HA.for id, HA.class "label-inline" ] [ H.text key ]
    ]


viewKeywords : Data.Kinto.Keywords -> (String -> Msg) -> List (H.Html Msg)
viewKeywords keywords msg =
    Dict.toList keywords
    |> List.concatMap (checkbox msg)


targetSelectedOptions : Decode.Decoder (List String)
targetSelectedOptions =
    Decode.at [ "target", "selectedOptions" ] <|
        collection <|
            Decode.field "value" Decode.string


collection : Decode.Decoder a -> Decode.Decoder (List a)
collection decoder =
    -- Taken from elm-community/json-extra
    Decode.field "length" Decode.int
        |> Decode.andThen
            (\length ->
                List.range 0 (length - 1)
                    |> List.map (\index -> Decode.field (String.fromInt index) decoder)
                    |> combine
            )


combine : List (Decode.Decoder a) -> Decode.Decoder (List a)
combine =
    -- Taken from elm-community/json-extra
    List.foldr (Decode.map2 (::)) (Decode.succeed [])

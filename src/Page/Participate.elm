module Page.Participate exposing (Model, Msg(..), init, update, view)

import Data.Kinto exposing (KintoData(..), NewVideo, Video, emptyNewVideo, emptyVideo)
import Data.Session exposing (Session)
import Dict
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Decode as Decode
import Kinto
import Page.Utils
import Ports
import Request.KintoUpcoming
import Route
import Task
import Time


type alias Model =
    { newVideo : NewVideo
    , newVideoKintoData : KintoData Video
    , videoObjectUrl : Maybe String
    , progress : Page.Utils.Progress
    , preSelectedKeywords : Keywords
    , freeformKeywords : String
    }


type alias Keywords =
    Dict.Dict String Bool


noKeywords : Dict.Dict String Bool
noKeywords =
    Data.Kinto.keywordList
        |> List.map (\( keyword, _ ) -> ( keyword, False ))
        |> Dict.fromList


type Credentials
    = Credentials ( String, String )


type Msg
    = UpdateVideoForm NewVideo
    | GetTimestamp
    | SubmitNewVideo Time.Posix
    | DiscardNotification
    | VideoSelected
    | VideoObjectUrlReceived Decode.Value
    | ProgressUpdated Decode.Value
    | AttachmentSent String
    | UpdatePreSelectedKeywords String
    | UpdateFreeformKeywords String


init : Session -> ( Model, Cmd Msg )
init session =
    ( { newVideo = emptyNewVideo
      , newVideoKintoData = NotRequested
      , videoObjectUrl = Nothing
      , progress = Page.Utils.emptyProgress
      , preSelectedKeywords = noKeywords
      , freeformKeywords = ""
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update { userData } msg model =
    case msg of
        UpdateVideoForm video ->
            ( { model | newVideo = video }, Cmd.none )

        GetTimestamp ->
            ( model, Task.perform SubmitNewVideo Time.now )

        SubmitNewVideo timestamp ->
            case userData.profile of
                Just profile ->
                    let
                        newVideo =
                            model.newVideo

                        timestampedVideo =
                            { newVideo | creation_date = timestamp }

                        updatedKeywords =
                            model.freeformKeywords
                                -- Split the keywords into a list
                                |> String.split ","
                                -- Remove the extraneous spaces
                                |> List.map String.trim
                                -- Remove the empty keywords
                                |> List.filter (\keyword -> keyword /= "")
                                -- Add the keywords to the current video keywords
                                |> List.foldl
                                    (\keyword keywords ->
                                        Dict.insert keyword True keywords
                                    )
                                    model.preSelectedKeywords

                        videoToSubmit =
                            { timestampedVideo
                                | keywords = keywordsToList updatedKeywords
                                , profile = profile
                            }

                        submitVideoData : Ports.SubmitVideoData
                        submitVideoData =
                            { nodeID = "video"
                            , videoNodeID = "uploaded-video"
                            , videoData = Data.Kinto.encodeNewVideoData videoToSubmit
                            , login = userData.username
                            , password = userData.password
                            }
                    in
                    ( { model
                        | newVideoKintoData = Requested
                        , newVideo = videoToSubmit
                      }
                    , Ports.submitVideo submitVideoData
                    )

                Nothing ->
                    -- Not profile information in the session? We should never reach this state.
                    ( model, Cmd.none )

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
                progress =
                    Decode.decodeValue Page.Utils.progressDecoder value
                        |> Result.withDefault Page.Utils.emptyProgress
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
                , freeformKeywords = ""
                , videoObjectUrl = Nothing
                , progress = Page.Utils.emptyProgress
              }
            , Cmd.none
            )

        UpdatePreSelectedKeywords keyword ->
            ( { model | preSelectedKeywords = toggleKeyword keyword model.preSelectedKeywords }
            , Cmd.none
            )

        UpdateFreeformKeywords keywords ->
            ( { model | freeformKeywords = keywords }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view { userData } model =
    ( "Je participe !"
    , [ H.div [ HA.class "main" ]
            [ H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ displayKintoData model.newVideoKintoData
                    , H.p [] [ H.text "Vous aimeriez avoir l'avis de vos collègues sur une problématique ou souhaitez poster une vidéo pour aider le collectif, vous êtes au bon endroit !" ]
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
                    , if not <| Data.Session.isLoggedIn userData then
                        Page.Utils.viewConnectNow "Pour ajouter une contribution veuillez vous " "connecter"

                      else
                        displaySubmitVideoForm model
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
        , progress : Page.Utils.Progress
        , preSelectedKeywords : Keywords
        , freeformKeywords : String
    }
    -> H.Html Msg
displaySubmitVideoForm { newVideo, newVideoKintoData, videoObjectUrl, progress, preSelectedKeywords, freeformKeywords } =
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
                    , Page.Utils.onFileSelected VideoSelected
                    ]
                    []
                , H.span [ HA.class "file-cta" ]
                    [ H.span [ HA.class "file-icon" ]
                        [ H.i [ HA.class "fas fa-upload" ] []
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
                , H.input
                    [ HA.id "grade-cp-ce1"
                    , HA.type_ "radio"
                    , HA.name "grade"
                    , HA.checked <| newVideo.grade == "CP et CE1"
                    , HE.onInput (\grade -> UpdateVideoForm { newVideo | grade = "CP et CE1" })
                    ]
                    []
                , H.label [ HA.for "grade-cp-ce1", HA.class "label-inline" ]
                    [ H.text "CP et CE1" ]
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
                        preSelectedKeywords
                        UpdatePreSelectedKeywords
                )
            ]
        , formInput
            H.input
            "freeform-keyword"
            "Préciser (parmi les mots clés grisés ci-dessus) ou ajouter des mots clés"
            "Liste de mots clés séparés par des virgules"
            freeformKeywords
            UpdateFreeformKeywords
            videoSelected
        , H.button
            [ HA.type_ "submit"
            , HA.class "button"
            , HA.disabled (newVideo.title == "")
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
                    [ H.i [ HA.class "fas fa-times" ] [] ]
                , H.text <| Kinto.errorToString error
                ]

        Received _ ->
            H.div [ HA.class "notification success closable" ]
                [ H.button
                    [ HA.class "close"
                    , HE.onClick DiscardNotification
                    ]
                    [ H.i [ HA.class "fas fa-times" ] [] ]
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


onSelectMultiple : (List String -> Msg) -> H.Attribute Msg
onSelectMultiple tagger =
    HE.on "change" (Decode.map tagger targetSelectedOptions)


checkbox : (String -> Msg) -> ( String, Bool ) -> H.Html Msg
checkbox msg ( key, value ) =
    let
        id =
            "keyword-" ++ key

        includedKeywords =
            -- Some keywords "include" other sub-keywords, display those to the user to help them choose
            Data.Kinto.keywordList
                |> List.filter (\( keyword, included ) -> keyword == key && included /= "")
                |> List.head
                |> Maybe.map
                    (\( keyword, included ) ->
                        [ H.span [ HA.class "included-keywords" ] [ H.text <| " (" ++ included ++ ")" ] ]
                    )
                |> Maybe.withDefault []
    in
    H.div [ HA.class "keywords" ]
        ([ H.input
            [ HA.type_ "checkbox"
            , HA.id id
            , HA.checked value
            , HE.onClick <| msg key
            ]
            []
         , H.label [ HA.for id, HA.class "label-inline" ] [ H.text key ]
         ]
            ++ includedKeywords
        )


viewKeywords : Keywords -> (String -> Msg) -> List (H.Html Msg)
viewKeywords keywords msg =
    Dict.toList keywords
        |> List.map (checkbox msg)


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


keywordsToList : Keywords -> List String
keywordsToList keywords =
    keywords
        |> Dict.filter (\key value -> value)
        |> Dict.keys


toggleKeyword : String -> Keywords -> Keywords
toggleKeyword keyword keywords =
    Dict.update keyword
        (\oldValue ->
            case oldValue of
                Just value ->
                    Just <| not value

                Nothing ->
                    Nothing
        )
        keywords

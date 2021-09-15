module Page.Participate exposing (Model, Msg(..), init, update, view)

import Data.PeerTube
import Data.Session exposing (Session)
import Dict
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode
import Page.Common.Components
import Page.Common.Notifications as Notifications
import Page.Common.Progress
import Page.Common.XHR
import Ports
import Route


type alias Model =
    { title : String
    , newVideo : Data.PeerTube.NewVideo
    , newVideoData : Data.PeerTube.RemoteData Data.PeerTube.VideoUploaded
    , videoObjectUrl : Maybe String
    , progress : Page.Common.Progress.Progress
    , preSelectedKeywords : Keywords
    , freeformKeywords : String
    , notifications : Notifications.Model
    }


type alias Keywords =
    Dict.Dict String Bool


noKeywords : Dict.Dict String Bool
noKeywords =
    Data.PeerTube.keywordList
        |> List.map (\keyword -> ( keyword, False ))
        |> Dict.fromList


type Msg
    = UpdateVideoForm Data.PeerTube.NewVideo
    | SubmitNewVideo
    | DiscardNotification
    | VideoSelected
    | VideoObjectUrlReceived Decode.Value
    | ProgressUpdated Decode.Value
    | VideoUploaded Decode.Value
    | UpdatePreSelectedKeywords String
    | UpdateFreeformKeywords String
    | NotificationMsg Notifications.Msg


init : Session -> ( Model, Cmd Msg )
init _ =
    ( { title = "Je participe !"
      , newVideo = Data.PeerTube.emptyNewVideo
      , newVideoData = Data.PeerTube.NotRequested
      , videoObjectUrl = Nothing
      , progress = Page.Common.Progress.empty
      , preSelectedKeywords = noKeywords
      , freeformKeywords = ""
      , notifications = Notifications.init
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg, Maybe Data.Session.Msg )
update { userInfo, userToken } msg model =
    case msg of
        UpdateVideoForm video ->
            ( { model | newVideo = video }, Cmd.none, Nothing )

        SubmitNewVideo ->
            if Data.Session.isLoggedIn userInfo then
                let
                    access_token =
                        userToken
                            |> Maybe.map .access_token
                            |> Maybe.withDefault ""

                    channelID =
                        userInfo
                            |> Maybe.map .channelID
                            -- TODO : replace the userInfo record with a type like `Anonymous | User String Int`
                            |> Maybe.withDefault 0

                    newVideo =
                        model.newVideo

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
                        { newVideo | keywords = keywordsToList updatedKeywords }

                    submitVideoData : Ports.SubmitVideoData
                    submitVideoData =
                        { nodeID = "video"
                        , videoNodeID = "uploaded-video"
                        , videoData = Data.PeerTube.encodeNewVideoData videoToSubmit
                        , channelID = channelID
                        , access_token = access_token
                        }
                in
                ( { model | newVideoData = Data.PeerTube.Requested }
                , Ports.submitVideo submitVideoData
                , Nothing
                )

            else
                -- No profile information in the session? We should never reach this state.
                ( model, Cmd.none, Nothing )

        DiscardNotification ->
            ( { model | newVideoData = Data.PeerTube.NotRequested }, Cmd.none, Nothing )

        VideoSelected ->
            ( model, Ports.videoSelected "video", Nothing )

        VideoObjectUrlReceived value ->
            let
                objectUrl =
                    Decode.decodeValue Decode.string value
            in
            ( { model | videoObjectUrl = Result.toMaybe objectUrl }, Cmd.none, Nothing )

        ProgressUpdated value ->
            let
                progress =
                    Decode.decodeValue Page.Common.Progress.decoder value
                        |> Result.withDefault Page.Common.Progress.empty
            in
            ( { model | progress = progress }, Cmd.none, Nothing )

        VideoUploaded response ->
            let
                updatedModel =
                    { model
                        | newVideo = Data.PeerTube.emptyNewVideo
                        , freeformKeywords = ""
                        , videoObjectUrl = Nothing
                        , progress = Page.Common.Progress.empty
                    }
            in
            case Decode.decodeValue Page.Common.XHR.decoder response of
                Ok (Page.Common.XHR.Success stringBody) ->
                    let
                        videoUploadResult =
                            case Decode.decodeString Data.PeerTube.videoUploadedDecoder stringBody of
                                Ok videoUploaded ->
                                    Data.PeerTube.Received videoUploaded

                                Err _ ->
                                    Data.PeerTube.Failed "Échec de l'envoi de la vidéo"
                    in
                    ( { updatedModel | newVideoData = videoUploadResult }
                    , Cmd.none
                    , Nothing
                    )

                Ok (Page.Common.XHR.BadStatus status _) ->
                    ( { updatedModel
                        | notifications =
                            "Échec de l'envoi de la vidéo"
                                |> Notifications.addError model.notifications
                        , newVideoData = Data.PeerTube.Failed "Échec de l'envoi de la vidéo"
                      }
                    , Cmd.none
                    , if status == 401 then
                        Just Data.Session.Logout

                      else
                        Nothing
                    )

                Err _ ->
                    ( { updatedModel
                        | notifications =
                            "Échec de l'envoi de la vidéo"
                                |> Notifications.addError model.notifications
                        , newVideoData = Data.PeerTube.Failed "Échec de l'envoi de la vidéo"
                      }
                    , Cmd.none
                    , Nothing
                    )

        UpdatePreSelectedKeywords keyword ->
            ( { model | preSelectedKeywords = toggleKeyword keyword model.preSelectedKeywords }
            , Cmd.none
            , Nothing
            )

        UpdateFreeformKeywords keywords ->
            ( { model | freeformKeywords = keywords }, Cmd.none, Nothing )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }
            , Cmd.none
            , Nothing
            )


view : Session -> Model -> Page.Common.Components.Document Msg
view { userInfo } model =
    { title = model.title
    , pageTitle = model.title
    , pageSubTitle = "Partagez une vidéo"
    , body =
        [ H.div [ HA.class "participate_intro" ]
            [ displayRemoteData model.newVideoData
            , H.h1 []
                [ H.text "Je participe !"
                ]
            , H.p [] [ H.text "Vous aimeriez avoir l'avis de vos collègues sur une problématique ou souhaitez poster une vidéo pour aider le collectif, vous êtes au bon endroit !" ]
            , H.p []
                [ H.text "Pensez bien à faire signer les autorisations de droit à l'image !"
                , H.br [] []
                , H.text "Des demandes d’autorisation sont disponibles ici : "
                , H.a [ HA.href "%PUBLIC_URL%/documents/Autorisation-captation-image-majeur_2017.pdf" ]
                    [ H.text "autorisation adulte" ]
                , H.text " - "
                , H.a [ HA.href "%PUBLIC_URL%/documents/Autorisation-captation-image-mineur_2017.pdf" ]
                    [ H.text "autorisation mineur" ]
                ]
            ]
        , if not <| Data.Session.isLoggedIn userInfo then
            Page.Common.Components.viewConnectNow "Pour ajouter une contribution veuillez vous " "connecter"

          else
            displaySubmitVideoForm model
        ]
    }


displaySubmitVideoForm :
    { a
        | newVideo : Data.PeerTube.NewVideo
        , newVideoData : Data.PeerTube.RemoteData Data.PeerTube.VideoUploaded
        , videoObjectUrl : Maybe String
        , progress : Page.Common.Progress.Progress
        , preSelectedKeywords : Keywords
        , freeformKeywords : String
    }
    -> H.Html Msg
displaySubmitVideoForm { newVideo, newVideoData, videoObjectUrl, progress, preSelectedKeywords, freeformKeywords } =
    let
        videoSelected =
            videoObjectUrl
                /= Nothing
    in
    H.form [ HE.onSubmit SubmitNewVideo, HA.class "upload_steps" ]
        [ H.div
            [ HA.style "display" <|
                if newVideoData == Data.PeerTube.NotRequested then
                    "block"

                else
                    "none"
            ]
            [ H.h2 [ HA.class "upload-step_title" ]
                [ H.div [ HA.class "upload-step_icon" ]
                    [ H.img [ HA.src "%PUBLIC_URL%/images/icons/32x32/download_32_purple.svg" ] []
                    ]
                , H.text "Étape 1 : Télécharger votre vidéo"
                ]
            , displayVideo
            , H.div
                [ HA.class "upload-step upload-video"
                , HA.style "display"
                    (if videoSelected then
                        "none"

                     else
                        "block"
                    )
                ]
                [ H.label []
                    [ H.input
                        [ HA.class "file-input"
                        , HA.type_ "file"
                        , HA.id "video"
                        , HA.accept "video/*"
                        , Page.Common.Components.onFileSelected VideoSelected
                        ]
                        []
                    , H.span [ HA.class "btn" ]
                        [ H.span [ HA.class "file-label" ] [ H.text "Envoyer un fichier vidéo" ]
                        ]
                    ]
                ]
            , H.h2
                [ HA.class "upload-step_title"
                , HA.style "display"
                    (if videoSelected then
                        "flex"

                     else
                        "none"
                    )
                ]
                [ H.div [ HA.class "upload-step_icon" ]
                    [ H.img [ HA.src "%PUBLIC_URL%/images/icons/32x32/info_32_purple.svg" ] []
                    ]
                , H.text "Étape 2 : À propos de votre vidéo"
                ]
            , H.div
                [ HA.class "upload-step"
                , HA.style "display"
                    (if videoSelected then
                        "block"

                     else
                        "none"
                    )
                ]
                [ formInput
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
                    "Description succincte, ville, académie (mise en forme possible avec Markdown)"
                    newVideo.description
                    (\description -> UpdateVideoForm { newVideo | description = description })
                    videoSelected
                , H.div
                    [ HA.style "display"
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
                ]
            , H.h2
                [ HA.class "upload-step_title"
                , HA.style "display"
                    (if videoSelected then
                        "flex"

                     else
                        "none"
                    )
                ]
                [ H.div [ HA.class "upload-step_icon" ]
                    [ H.img [ HA.src "%PUBLIC_URL%/images/icons/32x32/submit_32_purple.svg" ] []
                    ]
                , H.text "Étape 3 : Soumettez votre vidéo"
                ]
            , H.div [ HA.class "upload-step" ]
                [ H.button
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
                ]
            ]
        , H.div
            [ HA.style "display" <|
                if newVideoData == Data.PeerTube.Requested then
                    "block"

                else
                    "none"
            ]
            [ H.div [ HA.class "upload-step" ]
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
        , H.div
            [ HA.style "display" <|
                if newVideoData /= Data.PeerTube.NotRequested && newVideoData /= Data.PeerTube.Requested then
                    "block"

                else
                    "none"
            ]
            [ H.div [ HA.class "upload-step" ]
                [ H.h2 [] [ H.text "Merci pour la vidéo !" ]
                , H.text "Vous recevrez un email lors de sa publication. Vous pouvez en poster une autre ou "
                , H.a [ Route.href Route.Home ] [ H.text "retourner à la liste de vidéos" ]
                ]
            ]
        ]


displayVideo : H.Html Msg
displayVideo =
    H.div [ HA.style "display" "none", HA.class "upload-step upload-step_thumbnail" ]
        [ H.video
            [ HA.controls True
            , HA.id "uploaded-video"
            ]
            []
        , H.p [] [ H.text "Déplacer le curseur de la vidéo ci-dessus pour changer la miniature de la vidéo." ]
        , H.canvas [ HA.id "thumbnail-preview", HA.style "display" "none" ] []
        ]


displayRemoteData : Data.PeerTube.RemoteData Data.PeerTube.VideoUploaded -> H.Html Msg
displayRemoteData remoteData =
    case remoteData of
        Data.PeerTube.Failed error ->
            H.div [ HA.class "notification error closable" ]
                [ H.button
                    [ HA.class "close"
                    , HE.onClick DiscardNotification
                    ]
                    [ H.i [ HA.class "fas fa-times" ] [] ]
                , H.text error
                ]

        Data.PeerTube.Received _ ->
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
        [ HA.style "display"
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


checkbox : (String -> Msg) -> ( String, Bool ) -> H.Html Msg
checkbox msg ( key, value ) =
    let
        id =
            "keyword-" ++ key
    in
    H.div [ HA.class "keywords" ]
        [ H.input
            [ HA.type_ "checkbox"
            , HA.id id
            , HA.checked value
            , HE.onClick <| msg key
            ]
            []
        , H.label [ HA.for id, HA.class "label-inline" ] [ H.text key ]
        ]


viewKeywords : Keywords -> (String -> Msg) -> List (H.Html Msg)
viewKeywords keywords msg =
    Dict.toList keywords
        |> List.map (checkbox msg)


keywordsToList : Keywords -> List String
keywordsToList keywords =
    keywords
        |> Dict.filter (\_ value -> value)
        |> Dict.keys


toggleKeyword : String -> Keywords -> Keywords
toggleKeyword keyword keywords =
    Dict.update keyword (Maybe.map not) keywords

module Page.Utils exposing
    ( ButtonState(..)
    , Progress
    , button
    , emptyProgress
    , onChange
    , onFileSelected
    , optgroup
    , posixToDate
    , progressDecoder
    , submitButton
    , viewConnectNow
    , viewPublicVideo
    , viewVideo
    , viewVideoModal
    , viewVideoPlayer
    )

import Data.Kinto
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Markdown
import Route
import Time



---- BUTTONS ----


type ButtonState
    = Disabled
    | Loading
    | NotLoading


submitButton : String -> ButtonState -> H.Html msg
submitButton label buttonState =
    button label buttonState Nothing


button : String -> ButtonState -> Maybe msg -> H.Html msg
button label buttonState maybeOnClick =
    let
        loadingAttrs =
            case buttonState of
                Disabled ->
                    [ HA.type_ "submit"
                    , HA.class "button"
                    , HA.disabled True
                    ]

                Loading ->
                    [ HA.type_ "submit"
                    , HA.class "button button-loader"
                    , HA.disabled True
                    ]

                NotLoading ->
                    [ HA.type_ "submit"
                    , HA.class "button"
                    ]

        onClickAttr =
            maybeOnClick
                |> Maybe.map (\onClick -> [ HE.onClick onClick ])
                |> Maybe.withDefault []
    in
    H.button
        (loadingAttrs ++ onClickAttr)
        [ if buttonState == Loading then
            H.i [ HA.class "fas fa-spinner fa-spin" ] []

          else
            H.text label
        ]



---- VIDEOS ----


viewVideo : Time.Zone -> msg -> List (H.Html msg) -> Data.Kinto.Video -> H.Html msg
viewVideo timezone toggleVideo footerNodes video =
    let
        keywordsNode =
            if video.keywords /= [] then
                [ H.div [ HA.class "card__extra" ]
                    (video.keywords
                        |> List.map
                            (\keyword ->
                                H.div [ HA.class "label" ]
                                    [ H.text keyword ]
                            )
                    )
                ]

            else
                []

        cardNodes =
            [ H.div
                [ HA.class "card__cover" ]
                [ H.img
                    [ HA.alt video.title
                    , HA.src video.thumbnail
                    , HE.onClick toggleVideo
                    ]
                    []
                ]
            , H.div
                [ HA.class "card__content" ]
                [ H.h3 [] [ H.text video.title ]
                , H.div [ HA.class "card__meta" ]
                    [ H.time [] [ H.text <| posixToDate timezone video.creation_date ] ]
                , Markdown.toHtml [] video.description
                ]
            ]
    in
    H.div
        [ HA.class "card" ]
        (cardNodes ++ keywordsNode ++ footerNodes)


viewPublicVideo : Time.Zone -> Time.Posix -> Data.Kinto.Video -> H.Html msg
viewPublicVideo timezone timestamp video =
    let
        keywordsNode =
            if video.keywords /= [] then
                [ H.div [ HA.class "card__extra" ]
                    (video.keywords
                        |> List.map
                            (\keyword ->
                                H.div [ HA.class "label" ]
                                    [ H.text keyword ]
                            )
                    )
                ]

            else
                []

        isVideoRecent =
            let
                timestampMillis =
                    Time.posixToMillis timestamp

                creationDateMillis =
                    Time.posixToMillis video.creation_date
            in
            if timestampMillis == 0 then
                -- The timestamp isn't initialized yet
                False

            else
                timestampMillis
                    - creationDateMillis
                    -- A video is recent if it's less than 15 days.
                    |> (>) (15 * 24 * 60 * 60 * 1000)

        cardNodes =
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
            , H.div
                [ HA.class "card__content" ]
                [ H.h3 [] [ H.text video.title ]
                , H.div [ HA.class "card__meta" ]
                    [ H.time [] [ H.text <| posixToDate timezone video.creation_date ] ]
                , Markdown.toHtml [] video.description
                ]
            ]
    in
    H.a
        [ HA.class "card"
        , Route.href <| Route.Video video.id video.title
        ]
        (cardNodes ++ keywordsNode)


viewVideoPlayer : Data.Kinto.Attachment -> H.Html msg
viewVideoPlayer attachment =
    H.video
        [ HA.src <| attachment.location

        -- For some reason, using HA.type_ doesn't properly add the mimetype
        , HA.attribute "type" attachment.mimetype
        , HA.controls True
        , HA.preload "metadata"
        ]
        [ H.text "Désolé, votre navigateur ne supporte pas le format de cette video" ]


viewVideoModal : (Data.Kinto.Video -> msg) -> Maybe Data.Kinto.Video -> H.Html msg
viewVideoModal toggleVideo activeVideo =
    case activeVideo of
        Nothing ->
            H.div [] []

        Just video ->
            H.div
                [ HA.class "modal__backdrop is-active"
                , HE.onClick (toggleVideo video)
                ]
                [ H.div [ HA.class "modal" ] [ viewVideoPlayer video.attachment ]
                , H.button [ HA.class "modal__close" ]
                    [ H.i [ HA.class "fas fa-times fa-2x" ] [] ]
                ]



---- DATES ----


posixToDate : Time.Zone -> Time.Posix -> String
posixToDate timezone posix =
    let
        year =
            String.fromInt <| Time.toYear timezone posix

        month =
            case Time.toMonth timezone posix of
                Time.Jan ->
                    "01"

                Time.Feb ->
                    "02"

                Time.Mar ->
                    "03"

                Time.Apr ->
                    "04"

                Time.May ->
                    "05"

                Time.Jun ->
                    "06"

                Time.Jul ->
                    "07"

                Time.Aug ->
                    "08"

                Time.Sep ->
                    "09"

                Time.Oct ->
                    "10"

                Time.Nov ->
                    "11"

                Time.Dec ->
                    "12"

        day =
            String.fromInt <| Time.toDay timezone posix
    in
    year ++ "-" ++ month ++ "-" ++ day



---- FORMS AND EVENTS ----


onChange : (String -> msg) -> H.Attribute msg
onChange tagger =
    HE.on "change" (Decode.map tagger HE.targetValue)


optgroup : String -> List (H.Html msg) -> H.Html msg
optgroup label nodes =
    H.optgroup [ HA.property "label" <| Encode.string label ] nodes


viewConnectNow : String -> String -> H.Html msg
viewConnectNow label linkLabel =
    H.div [ HA.class "section section-white" ]
        [ H.div [ HA.class "container" ]
            [ H.text label
            , H.a [ Route.href Route.Login ] [ H.text linkLabel ]
            ]
        ]


onFileSelected : msg -> H.Attribute msg
onFileSelected msg =
    HE.on "change" (Decode.succeed msg)



---- HTTP progress updates ----


type alias Progress =
    { percentage : Int
    , message : String
    }


emptyProgress : Progress
emptyProgress =
    { percentage = 0, message = "" }


progressDecoder =
    Decode.succeed Progress
        |> Pipeline.required "percentage" Decode.int
        |> Pipeline.required "message" Decode.string

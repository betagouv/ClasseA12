module Page.Utils exposing
    ( ButtonState(..)
    , button
    , errorList
    , errorNotification
    , posixToDate
    , notification
    , submitButton
    , successNotification
    , viewVideo
    , viewVideoModal
    , viewVideoPlayer
    )

import Data.Kinto
import Html as H
import Html.Attributes as HA
import Html.Events as HE
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
            H.i [ HA.class "fa fa-spinner fa-spin" ] []

          else
            H.text label
        ]



---- NOTIFICATIONS ----


errorList : List String -> (Int -> msg) -> H.Html msg
errorList errors discardErrorMsg =
    H.div []
        (errors
            |> List.indexedMap
                (\index error ->
                    errorNotification [ H.text error ] (discardErrorMsg index)
                )
        )


notification : String -> List (H.Html msg) -> msg -> H.Html msg
notification status content discardMsg =
    H.div [ HA.class <| "notification closable " ++ status ]
        ([ H.button
            [ HA.class "close"
            , HE.onClick discardMsg
            ]
            [ H.i [ HA.class "fa fa-times" ] [] ]
         ]
            ++ content
        )


successNotification : List (H.Html msg) -> msg -> H.Html msg
successNotification content discardMsg =
    notification "success" content discardMsg


errorNotification : List (H.Html msg) -> msg -> H.Html msg
errorNotification content discardMsg =
    notification "error" content discardMsg



---- VIDEOS ----


viewVideo : Time.Zone -> msg -> List (H.Html msg) -> Data.Kinto.Video -> H.Html msg
viewVideo timezone toggleVideo footerNodes video =
    let
        keywordsNode =
            if video.keywords /= [] then
                [ H.div [ HA.class "card__extra" ]
                    (List.map
                        (\keyword ->
                            H.div [ HA.class "label" ]
                                [ H.text keyword ]
                        )
                        video.keywords
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
                , H.p [] [ H.text video.description ]
                ]
            ]
    in
    H.div
        [ HA.class "card" ]
        (cardNodes ++ keywordsNode ++ footerNodes)


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
                    [ H.i [ HA.class "fa fa-times fa-2x" ] [] ]
                ]


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

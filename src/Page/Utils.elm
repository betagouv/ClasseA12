module Page.Utils exposing
    ( ButtonState(..)
    , button
    , errorList
    , errorNotification
    , notification
    , submitButton
    , successNotification
    )

import Html as H
import Html.Attributes as HA
import Html.Events as HE


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

module Page.Utils exposing (ButtonState(..), submitButton)

import Html as H
import Html.Attributes as HA

type ButtonState
    = Disabled
    | Loading
    | NotLoading


submitButton : String -> ButtonState -> H.Html msg
submitButton label buttonState =
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
    in
    H.button
        loadingAttrs
        [ if buttonState == Loading then
            H.i [ HA.class "fa fa-spinner fa-spin" ] []

          else
            H.text label
        ]
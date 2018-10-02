module Page.Counter exposing (Model, Msg, init, update, view)

import Data.Session exposing (Session)
import Html as Html exposing (..)
import Html.Attributes
import Html.Events exposing (onClick)
import Route


type alias Model =
    Int


type Msg
    = Inc


init : Session -> ( Model, Cmd Msg )
init session =
    ( 0, Cmd.none )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        Inc ->
            ( model + 1
            , Cmd.none
            )


view : Session -> Model -> ( String, List (Html Msg) )
view _ model =
    ( "Second Page"
    , [ h1 [] [ text "Second page" ]
      , p [] [ text "This is the second page, featuring a counter." ]
      , p []
            [ button
                [ Html.Attributes.class "counter-buttons"
                , onClick Inc
                ]
                [ text "+" ]
            , strong [] [ text (String.fromInt model) ]
            ]
      , p [] [ a [ Route.href Route.Home ] [ text "Back home" ] ]
      ]
    )

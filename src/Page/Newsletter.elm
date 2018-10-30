module Page.Newsletter exposing (Model, Msg(..), init, update, view)

import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA


type alias Model =
    {}


type Msg
    = NoOp


init : Session -> ( Model, Cmd Msg )
init session =
    ( {}, Cmd.none )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    ( model, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view _ model =
    ( "Inscrivez-vous à notre infolettre"
    , [ H.div [ HA.class "main" ]
            [ H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ H.text "#the newsletter page here#" ]
                ]
            ]
      ]
    )

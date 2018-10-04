module Page.About exposing (Model, Msg(..), init, update, view)

import Data.Session exposing (Session)
import Data.Videos
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
    ( "Classe à 12 ?"
    , [ H.div [ HA.class "row columns is-multiline" ]
            [ H.text "#the about page here#" ]
      ]
    )

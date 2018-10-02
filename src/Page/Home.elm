module Page.Home exposing (Model, Msg(..), init, update, view)

import Browser exposing (Document)
import Data.Session exposing (Session)
import Data.Videos
import Html as H
import Html.Attributes as HA
import Http


type alias Model =
    { videoList : List Video
    }


type alias Video =
    { url : String
    , thumbnail : String
    , title : String
    , author : String
    , date : String
    }


type Msg
    = NoOp


init : Session -> ( Model, Cmd Msg )
init session =
    ( { videoList = Data.Videos.videoList }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    ( model, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view _ model =
    ( "Liste des vidéos"
    , model.videoList
        |> List.map
            (\video ->
                H.a [ HA.href "#" ]
                    [ H.img [ HA.src video.thumbnail ] []
                    ]
            )
    )

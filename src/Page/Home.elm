module Page.Home exposing (Model, Msg(..), init, update, view)

import Data.Session exposing (Session)
import Data.Videos
import Html as H
import Html.Attributes as HA


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
    , [ H.div
            [ HA.class "box" ]
            [ H.div [ HA.class "field has-addons" ]
                [ H.div [ HA.class "control is-expanded" ]
                    [ H.input [ HA.class "input", HA.type_ "search", HA.placeholder "Search video titles" ] [] ]
                , H.div [ HA.class "control" ]
                    [ H.a [ HA.class "button is-info" ] [ H.text "Search" ] ]
                ]
            ]
      , H.div [ HA.class "row columns is-multiline" ]
            (model.videoList
                |> List.map
                    (\video ->
                        H.div [ HA.class "column is-one-quarter" ]
                            [ H.a [ HA.href video.url ]
                                [ H.div [ HA.class "card large round" ]
                                    [ H.div [ HA.class "card-image " ]
                                        [ H.figure [ HA.class "image" ]
                                            [ H.img
                                                [ HA.src video.thumbnail
                                                , HA.alt <| "Thumbnail of the video titled: " ++ video.title
                                                ]
                                                []
                                            ]
                                        ]
                                    , H.div [ HA.class "card-content" ]
                                        [ H.div [ HA.class "content" ]
                                            [ H.text video.author
                                            , H.p [ HA.class "video-date" ] [ H.text video.date ]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                    )
            )
      ]
    )

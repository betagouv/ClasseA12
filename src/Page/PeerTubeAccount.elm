module Page.PeerTubeAccount exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Data.PeerTube exposing (Account, RemoteData(..))
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Http
import Markdown
import Request.PeerTube exposing (getAccount)


type alias Model =
    { accountName : String, title : String, accountData : RemoteData Account }


type Msg
    = NoOp
    | AccountReceived (Result Http.Error Account)


init : String -> Session -> ( Model, Cmd Msg )
init accountName session =
    ( { accountName = accountName, title = "", accountData = Requested }, getAccount accountName AccountReceived )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        AccountReceived (Ok account) ->
            ( { model | accountData = Received account }, Cmd.none )

        AccountReceived (Err error) ->
            ( { model | accountData = Failed "Something went wrong" }, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view session model =
    let
        accountElements : List (H.Html Msg)
        accountElements =
            case model.accountData of
                Received account ->
                    [ H.h1 [] [ H.text account.displayName ], H.p [] [ Markdown.toHtml [] account.description ] ]

                Requested ->
                    [ H.text "Chargement…" ]

                _ ->
                    [ H.text "tout le reste" ]
    in
    ( model.title
    , [ H.article [] accountElements ]
    )

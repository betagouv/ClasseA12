module Page.Search exposing (Model, Msg(..), init, update, view)

import Data.PeerTube
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Page.Common.Components
import Page.Common.Video
import Request.PeerTube
import Route
import Url


type alias Model =
    { title : String
    , keyword : String
    , videoListData : Data.PeerTube.RemoteData (List Data.PeerTube.Video)
    }


type Msg
    = VideoListReceived String (Result Http.Error (List Data.PeerTube.Video))


init : Maybe String -> Session -> ( Model, Cmd Msg )
init search session =
    let
        emptyVideoListParams =
            Request.PeerTube.emptyVideoListParams

        videoListParams : Request.PeerTube.VideoListParams
        videoListParams =
            { emptyVideoListParams | count = 20 }
    in
    case search of
        Nothing ->
            ( { title = "Liste des vidéos récentes"
              , keyword = "Nouveautés"
              , videoListData = Data.PeerTube.Requested
              }
            , Request.PeerTube.getVideoList videoListParams session.peerTubeURL (VideoListReceived "Nouveautés")
            )

        Just keyword ->
            let
                decoded =
                    keyword
                        |> Url.percentDecode
                        |> Maybe.withDefault ""
            in
            ( { title = "Liste des vidéos dans la catégorie " ++ decoded
              , keyword = decoded
              , videoListData = Data.PeerTube.Requested
              }
            , Request.PeerTube.getVideoList
                (videoListParams |> Request.PeerTube.withKeyword keyword)
                session.peerTubeURL
                (VideoListReceived decoded)
            )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        VideoListReceived keyword (Ok videoList) ->
            ( { model | videoListData = Data.PeerTube.Received videoList }
            , Cmd.none
            )

        VideoListReceived keyword (Err error) ->
            ( { model | videoListData = Data.PeerTube.Failed "Échec de la récupération des vidéos" }
            , Cmd.none
            )


view : Session -> Model -> Page.Common.Components.Document Msg
view { staticFiles, peerTubeURL } ({ title, videoListData, keyword } as model) =
    { title = title
    , pageTitle =
        if keyword == "Nouveautés" then
            title

        else
            "Liste des vidéos"
    , pageSubTitle =
        if keyword == "Nouveautés" then
            ""

        else
            "dans la catégorie " ++ keyword
    , body =
        [ Page.Common.Video.viewCategory videoListData peerTubeURL keyword ]
    }

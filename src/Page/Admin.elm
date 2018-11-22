module Page.Admin exposing (Model, Msg(..), init, update, view)

import Data.Kinto exposing (Video)
import Data.Session exposing (LoginForm, Session, decodeSessionData, emptyLoginForm, encodeSessionData)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Kinto
import Page.Utils
import Ports
import Request.KintoUpcoming


type alias Model =
    { loginForm : LoginForm
    , videoListData : VideoListData
    , errorList : List String
    }


type alias VideoList =
    Kinto.Pager Video


type alias VideoListData =
    Data.Kinto.KintoData VideoList


type Msg
    = UpdateLoginForm LoginForm
    | Login
    | Logout
    | VideoListFetched (Result Kinto.Error VideoList)
    | DiscardError Int


init : Session -> ( Model, Cmd Msg )
init session =
    ( { loginForm = session.loginForm
      , videoListData = Data.Kinto.NotRequested
      , errorList = []
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        UpdateLoginForm loginForm ->
            ( { model | loginForm = loginForm }, Cmd.none )

        Login ->
            useLogin model

        Logout ->
            ( { model | loginForm = emptyLoginForm }, Ports.logoutSession () )

        VideoListFetched (Ok videoList) ->
            ( { model | videoListData = Data.Kinto.Received videoList }, Cmd.none )

        VideoListFetched (Err err) ->
            ( { model
                | videoListData = Data.Kinto.Failed err
                , errorList = [ Kinto.errorToString err ] ++ model.errorList
              }
            , Cmd.none
            )

        DiscardError index ->
            ( { model | errorList = List.take index model.errorList ++ List.drop (index + 1) model.errorList }
            , Cmd.none
            )



isLoginFormComplete : LoginForm -> Bool
isLoginFormComplete loginForm =
    loginForm.username /= "" && loginForm.password /= ""


useLogin : Model -> ( Model, Cmd Msg )
useLogin  model =
    if isLoginFormComplete model.loginForm then
        ( { model | videoListData = Data.Kinto.Requested }
        , Cmd.batch
            [ Request.KintoUpcoming.getVideoList model.loginForm.username model.loginForm.password VideoListFetched
            , Ports.saveSession <| encodeSessionData model.loginForm
            ]
        )

    else
        ( model, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view _ {errorList, videoListData, loginForm} =
    ( "Administration"
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src "./logo_ca12.png", HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "Administration" ]
                , H.p [] [ H.text "Modération des vidéos et des commentaires" ]
                ]
            ]
      , H.div [ HA.class "main" ]
            [ H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ Page.Utils.errorList errorList DiscardError
                    , case videoListData of
                        Data.Kinto.Received videoList ->
                            viewVideoList videoList

                        _ ->
                            viewLoginForm loginForm videoListData
                    ]
                ]
            ]
      ]
    )


viewVideoList : VideoList -> H.Html Msg
viewVideoList videoList =
    H.ul []
        (videoList.objects
            |> List.map
                (\video ->
                    H.li [] [ H.text video.title ]
                )
        )


viewLoginForm : LoginForm -> VideoListData -> H.Html Msg
viewLoginForm loginForm videoListData =
    let
        formComplete =
            isLoginFormComplete loginForm

        buttonState =
            if formComplete then
                case videoListData of
                    Data.Kinto.Requested ->
                        Page.Utils.Loading

                    _ ->
                        Page.Utils.NotLoading

            else
                Page.Utils.Disabled

        submitButton =
            Page.Utils.submitButton "Utiliser ces identifiants" buttonState
    in
    H.form
        [ HE.onSubmit Login ]
        [ H.h1 [] [ H.text "Formulaire de connexion" ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "username" ] [ H.text "Username" ]
            , H.input
                [ HA.type_ "text"
                , HA.id "username"
                , HA.value loginForm.username
                , HE.onInput <| \username -> UpdateLoginForm { loginForm | username = username }
                ]
                []
            ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "password" ] [ H.text "Password" ]
            , H.input
                [ HA.type_ "password"
                , HA.value loginForm.password
                , HE.onInput <| \password -> UpdateLoginForm { loginForm | password = password }
                ]
                []
            ]
        , submitButton
        ]

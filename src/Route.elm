module Route exposing (Route(..), fromUrl, href, pushUrl)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser)


type Route
    = Home
    | About
    | Participate
    | Newsletter
    | CGU
    | Convention
    | PrivacyPolicy
    | Admin
    | Video String String
    | Login
    | Register
    | ResetPassword
    | SetNewPassword String String
    | Activate String String
    | Profile


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map About (Parser.s "apropos")
        , Parser.map Participate (Parser.s "participer")
        , Parser.map Newsletter (Parser.s "infolettre")
        , Parser.map CGU (Parser.s "CGU")
        , Parser.map Convention (Parser.s "Charte")
        , Parser.map PrivacyPolicy (Parser.s "PolitiqueConfidentialite")
        , Parser.map Admin (Parser.s "admin")
        , Parser.map Video (Parser.s "video" </> Parser.string </> Parser.string)
        , Parser.map Login (Parser.s "connexion")
        , Parser.map Register (Parser.s "inscription")
        , Parser.map ResetPassword (Parser.s "oubli-mot-de-passe")
        , Parser.map SetNewPassword (Parser.s "nouveau-mot-de-passe" </> Parser.string </> Parser.string)
        , Parser.map Activate (Parser.s "activation" </> Parser.string </> Parser.string)
        , Parser.map Profile (Parser.s "profil")
        ]


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse parser url


href : Route -> Attribute msg
href route =
    Attr.href (toString route)


pushUrl : Nav.Key -> Route -> Cmd msg
pushUrl key route =
    Nav.pushUrl key (toString route)


toString : Route -> String
toString route =
    let
        pieces =
            case route of
                Home ->
                    []

                About ->
                    [ "apropos" ]

                Participate ->
                    [ "participer" ]

                Newsletter ->
                    [ "infolettre" ]

                CGU ->
                    [ "CGU" ]

                Convention ->
                    [ "Charte" ]

                PrivacyPolicy ->
                    [ "PolitiqueConfidentialite" ]

                Admin ->
                    [ "admin" ]

                Video videoID title ->
                    [ "video"
                    , videoID
                    , title
                        |> String.replace "." ""
                        |> Url.percentEncode
                    ]

                Login ->
                    [ "connexion" ]

                Register ->
                    [ "inscription" ]

                ResetPassword ->
                    [ "oubli-mot-de-passe" ]

                SetNewPassword username temporaryPassword ->
                    [ "nouveau-mot-de-passe"
                    , username
                    , temporaryPassword
                    ]

                Activate username activationKey ->
                    [ "activation"
                    , username
                    , activationKey
                    ]

                Profile ->
                    [ "profil" ]
    in
    "/" ++ String.join "/" pieces

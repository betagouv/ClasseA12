module Route exposing (Route(..), fromUrl, href, pushUrl, toString)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import String.Normalize
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser)


type Route
    = Home
    | PeerTube
    | PeerTubeVideo String
    | PeerTubeAccount String
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
    | Profile (Maybe String)
    | Comments


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map PeerTube (Parser.s "peertube")
        , Parser.map PeerTubeVideo (Parser.s "peertube" </> Parser.s "video" </> Parser.string)
        , Parser.map PeerTubeAccount (Parser.s "peertube" </> Parser.s "mon-compte" </> Parser.string)
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
        , Parser.map (Profile Nothing) (Parser.s "profil")
        , Parser.map (\profile -> Profile (Just profile)) (Parser.s "profil" </> Parser.string)
        , Parser.map Comments (Parser.s "commentaires")
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

                PeerTube ->
                    [ "peertube" ]

                PeerTubeVideo videoID ->
                    [ "peertube", "video", videoID ]

                PeerTubeAccount accountName ->
                    [ "peertube", "mon-compte", accountName ]

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
                        |> String.Normalize.slug
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

                Profile Nothing ->
                    [ "profil" ]

                Profile (Just profile) ->
                    [ "profil"
                    , profile
                    ]

                Comments ->
                    [ "commentaires" ]
    in
    "/" ++ String.join "/" pieces

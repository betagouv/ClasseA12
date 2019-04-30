module Route exposing (Route(..), fromUrl, href, pushUrl, toString)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import String.Normalize
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), (<?>), Parser)
import Url.Parser.Query as Query


type Route
    = Home
    | Search (Maybe String)
    | About
    | Participate
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
    | Profile String
    | Comments


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map (Search Nothing) (Parser.s "videos")
        , Parser.map (\search -> Search <| Just search) (Parser.s "videos" </> Parser.string)
        , Parser.map About (Parser.s "apropos")
        , Parser.map Participate (Parser.s "participer")
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
        , Parser.map Profile (Parser.s "profil" </> Parser.string)
        , Parser.map Comments (Parser.s "commentaires")

        -- PeerTube URL translations
        , Parser.map
            (\maybeUserID maybeVerificationString ->
                Activate
                    (Maybe.withDefault "badUserID" maybeUserID)
                    (Maybe.withDefault "badVerificationString" maybeVerificationString)
            )
            (Parser.s "verify-account"
                </> Parser.s "email"
                <?> Query.string "userId"
                <?> Query.string "verificationString"
            )
        , Parser.map
            (\maybeUserID maybeVerificationString ->
                SetNewPassword
                    (Maybe.withDefault "badUserID" maybeUserID)
                    (Maybe.withDefault "badVerificationString" maybeVerificationString)
            )
            (Parser.s "reset-password"
                <?> Query.string "userId"
                <?> Query.string "verificationString"
            )
        , Parser.map
            (\videoID -> Video videoID "lien vidéo d'un email")
            (Parser.s "videos" </> Parser.s "watch" </> Parser.string)
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

                Search search ->
                    search
                        |> Maybe.map
                            (\justSearch ->
                                [ "videos", Url.percentEncode justSearch ]
                            )
                        |> Maybe.withDefault [ "videos" ]

                About ->
                    [ "apropos" ]

                Participate ->
                    [ "participer" ]

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

                SetNewPassword userID verificationString ->
                    [ "nouveau-mot-de-passe"
                    , userID
                    , verificationString
                    ]

                Activate userID verificationString ->
                    [ "activation"
                    , userID
                    , verificationString
                    ]

                Profile profile ->
                    [ "profil"
                    , profile
                    ]

                Comments ->
                    [ "commentaires" ]
    in
    "/" ++ String.join "/" pieces

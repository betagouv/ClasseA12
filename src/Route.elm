module Route exposing (Route(..), VideoListQuery(..), fromUrl, href, hrefWithAnchor, pushUrl, toString)

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import String.Normalize
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), (<?>), Parser)
import Url.Parser.Query as Query


type Route
    = Home
    | AllVideos
    | VideoList VideoListQuery
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


type VideoListQuery
    = Latest
    | Playlist
    | FAQFlash
    | Keyword String
    | Search String
    | Favorites String
    | Published String


videoIDWithMaybeCommentIDParser : Parser (String -> a) a
videoIDWithMaybeCommentIDParser =
    -- If there's a comment ID in the URL (coming from a peertube email
    -- following a received comment) then drop it entirely.
    Parser.custom "VIDEO_ID" <|
        \segment ->
            segment
                |> String.split ";threadId="
                |> List.head


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map AllVideos (Parser.s "videos")
        , Parser.map (VideoList Latest) (Parser.s "videos-recentes")
        , Parser.map (VideoList FAQFlash) (Parser.s "videos-faq-flash")
        , Parser.map (VideoList Playlist) (Parser.s "videos-playlist")
        , Parser.map (\search -> VideoList <| Keyword search) (Parser.s "videos" </> Parser.string)
        , Parser.map (\search -> VideoList <| Search search) (Parser.s "videos-recherche" </> Parser.string)
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
        , Parser.map (\profile -> VideoList <| Favorites profile) (Parser.s "profil" </> Parser.string </> Parser.s "favoris")
        , Parser.map (\profile -> VideoList <| Published profile) (Parser.s "profil" </> Parser.string </> Parser.s "publiees")

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
            (Parser.s "videos" </> Parser.s "watch" </> videoIDWithMaybeCommentIDParser)
        , Parser.map Admin
            (Parser.s "admin" </> Parser.s "moderation" </> Parser.s "video-auto-blacklist" </> Parser.s "list")
        ]


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse parser url


href : Route -> Attribute msg
href route =
    Attr.href (toString route)


hrefWithAnchor : Route -> String -> Attribute msg
hrefWithAnchor route anchor =
    Attr.href (toString route ++ "#" ++ anchor)


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

                AllVideos ->
                    []

                VideoList query ->
                    case query of
                        Latest ->
                            [ "videos-recentes" ]

                        Playlist ->
                            [ "videos-playlist" ]

                        FAQFlash ->
                            [ "videos-faq-flash" ]

                        Keyword search ->
                            [ "videos", Url.percentEncode search ]

                        Search search ->
                            [ "videos-recherche", Url.percentEncode search ]

                        Favorites profile ->
                            [ "profil", Url.percentEncode profile, "favoris" ]

                        Published profile ->
                            [ "profil", Url.percentEncode profile, "publiees" ]

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

module Request.Kinto exposing (AnonymousClient(..), AuthClient(..), anonymousClient, authClient)

import Kinto


serverURL =
    "https://kinto.classea12.beta.gouv.fr/v1/"


type AuthClient
    = AuthClient Kinto.Client


type AnonymousClient
    = AnonymousClient Kinto.Client


authClient : String -> String -> AuthClient
authClient login password =
    AuthClient <| Kinto.client serverURL (Kinto.Basic login password)


anonymousClient : AnonymousClient
anonymousClient =
    AnonymousClient <| Kinto.client serverURL Kinto.NoAuth

module Request.Kinto exposing (AnonymousClient(..), AuthClient(..), anonymousClient, authClient)

import Kinto


type AuthClient
    = AuthClient Kinto.Client


type AnonymousClient
    = AnonymousClient Kinto.Client


authClient : String -> String -> String -> AuthClient
authClient serverURL login password =
    AuthClient <| Kinto.client serverURL (Kinto.Basic login password)


anonymousClient : String -> AnonymousClient
anonymousClient serverURL =
    AnonymousClient <| Kinto.client serverURL Kinto.NoAuth

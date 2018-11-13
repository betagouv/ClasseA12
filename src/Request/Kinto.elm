module Request.Kinto exposing (client)

import Kinto


client : String -> String -> Kinto.Client
client login password =
    Kinto.client "https://kinto.agopian.info/v1/" (Kinto.Basic login password)

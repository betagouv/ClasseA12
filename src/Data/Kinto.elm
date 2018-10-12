module Data.Kinto exposing (KintoData(..))

import Kinto


type KintoData a
    = NotRequested
    | Requested
    | Received a
    | Failed Kinto.Error

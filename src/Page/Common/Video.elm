module Page.Common.Video exposing (details, keywords, kintoDetails, player, shortDetails)

import Data.Kinto
import Data.PeerTube
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode
import Markdown
import Page.Common.Dates as Dates
import Route
import Time


player : msg -> Data.Kinto.Attachment -> H.Html msg
player canplayMessage attachment =
    H.video
        [ HA.src <| attachment.location

        -- For some reason, using HA.type_ doesn't properly add the mimetype
        , HA.attribute "type" attachment.mimetype
        , HA.controls True
        , HA.preload "metadata"
        , HE.on "canplay" (Decode.succeed canplayMessage)
        ]
        [ H.text "Désolé, votre navigateur ne supporte pas le format de cette video" ]


kintoDetails : Time.Zone -> Data.Kinto.Video -> Data.Kinto.ProfileData -> H.Html msg
kintoDetails timezone video profileData =
    let
        authorName =
            case profileData of
                Data.Kinto.Received profile ->
                    profile.name

                _ ->
                    video.profile
    in
    H.div
        [ HA.class "video-details" ]
        [ H.h3 [] [ H.text video.title ]
        , H.div []
            [ H.time [] [ H.text <| Dates.posixToDate timezone video.creation_date ]
            , H.text " "
            , H.a [ Route.href <| Route.Profile video.profile ] [ H.text authorName ]
            ]
        , Markdown.toHtml [] video.description
        ]


details : Data.PeerTube.Video -> H.Html msg
details video =
    H.div
        [ HA.class "video-details" ]
        [ H.h3 [] [ H.text video.name ]
        , H.div []
            [ H.time [] [ H.text <| Dates.formatStringDate video.publishedAt ]
            , H.text " "
            , H.a [ Route.href <| Route.Profile video.account.name ] [ H.text video.account.displayName ]
            ]
        , Markdown.toHtml [] video.description
        ]


shortDetails : Data.PeerTube.Video -> H.Html msg
shortDetails video =
    H.div
        [ HA.class "video-details" ]
        [ H.h3 [] [ H.text video.name ]
        , H.div []
            [ H.time [] [ H.text <| Dates.formatStringDate video.publishedAt ]
            ]
        ]


keywords : List String -> H.Html msg
keywords keywordList =
    if keywordList /= [] then
        keywordList
            |> List.map
                (\keyword ->
                    H.div [ HA.class "label" ]
                        [ H.a [ Route.href <| Route.Search (Just keyword) ]
                            [ H.text keyword ]
                        ]
                )
            |> H.div [ HA.class "video-keywords" ]

    else
        H.text ""

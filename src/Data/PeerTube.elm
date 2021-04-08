module Data.PeerTube exposing
    ( Account
    , Comment
    , FavoriteData
    , NewVideo
    , PartialUserInfo
    , Playlist
    , RemoteData(..)
    , UserInfo
    , UserToken
    , Video
    , VideoUploaded
    , accountDecoder
    , alternateCommentListDecoder
    , commentDecoder
    , commentListDecoder
    , emptyNewVideo
    , encodeComment
    , encodeNewVideoData
    , encodeUserInfo
    , encodeUserToken
    , keywordList
    , playlistDecoder
    , playlistVideoListDataDecoder
    , userInfoDecoder
    , userTokenDecoder
    , videoDecoder
    , videoListDataDecoder
    , videoUploadedDecoder
    )

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode


type alias UserToken =
    { access_token : String
    , expires_in : Int
    , refresh_token : String
    , token_type : String
    }


type alias PartialUserInfo =
    { username : String
    , channelID : Int
    }


type alias UserInfo =
    { username : String
    , channelID : Int
    , playlistID : Int
    }


type alias Account =
    { name : String
    , displayName : String
    , description : String
    }


type alias Video =
    { id : Int
    , previewPath : String
    , thumbnailPath : String
    , name : String
    , embedPath : String
    , uuid : String
    , description : String
    , account : Account
    , publishedAt : String
    , originallyPublishedAt : String
    , tags : List String
    , blacklisted : Bool
    , files : Maybe Files
    }


type alias Files =
    { fileUrl : String
    , fileDownloadUrl : String
    }


type alias NewVideo =
    { title : String
    , grade : String
    , keywords : List String
    , description : String
    }


type alias VideoUploaded =
    { id : Int
    , uuid : String
    }


emptyNewVideo : NewVideo
emptyNewVideo =
    { description = ""
    , title = ""
    , grade = ""
    , keywords = []
    }


type alias Comment =
    { id : Int
    , text : String
    , videoId : Int
    , createdAt : String
    , updatedAt : String
    , account : Account
    }


type alias Playlist =
    { id : Int
    , uuid : String
    , displayName : String
    }


type alias FavoriteData =
    { playlistID : Int
    , playlistItemID : Int
    }


type RemoteData a
    = NotRequested
    | Requested
    | Received a
    | Failed String


keywordList : List String
keywordList =
    [ "Gestion de groupe"
    , "Gestion de matériel"
    , "Co-intervention"
    , "Communication"
    , "DF à distance"
    , "Coordonnateur DF"
    , "Ressources"
    ]



---- DECODERS ----


videoListDataDecoder : Decode.Decoder (List Video)
videoListDataDecoder =
    Decode.field "data" videoListDecoder


videoListDecoder : Decode.Decoder (List Video)
videoListDecoder =
    Decode.list videoDecoder


playlistVideoListDataDecoder : Decode.Decoder (List Video)
playlistVideoListDataDecoder =
    Decode.field "data" playlistVideoListDecoder


playlistVideoListDecoder : Decode.Decoder (List Video)
playlistVideoListDecoder =
    Decode.list (Decode.field "video" videoDecoder)


accountDecoder : Decode.Decoder Account
accountDecoder =
    Decode.succeed Account
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "displayName" Decode.string
        |> Pipeline.optional "description" Decode.string ""


alternateAccountDecoder : Decode.Decoder Account
alternateAccountDecoder =
    -- When getting the full list of comments (not by thread/video), the linked
    -- account is formed differently than the one above
    Decode.succeed Account
        |> Pipeline.requiredAt [ "Actor", "preferredUsername" ] Decode.string
        |> Pipeline.required "name" Decode.string
        |> Pipeline.optional "description" Decode.string ""


videoDecoder : Decode.Decoder Video
videoDecoder =
    Decode.succeed Video
        |> Pipeline.required "id" Decode.int
        |> Pipeline.optional "previewPath" Decode.string ""
        |> Pipeline.optional "thumbnailPath" Decode.string ""
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "embedPath" Decode.string
        |> Pipeline.required "uuid" Decode.string
        |> Pipeline.optional "description" Decode.string ""
        |> Pipeline.required "account" accountDecoder
        |> Pipeline.required "publishedAt" Decode.string
        |> Pipeline.optional "originallyPublishedAt" Decode.string ""
        |> Pipeline.optional "tags" (Decode.list Decode.string) []
        |> Pipeline.optional "blacklisted" Decode.bool False
        |> Pipeline.optional "files" videoFilesDecoder Nothing


videoFilesDecoder : Decode.Decoder (Maybe Files)
videoFilesDecoder =
    Decode.list
        (Decode.succeed Files
            |> Pipeline.required "fileUrl" Decode.string
            |> Pipeline.required "fileDownloadUrl" Decode.string
        )
        |> Decode.map List.head


userTokenDecoder : Decode.Decoder UserToken
userTokenDecoder =
    Decode.succeed UserToken
        |> Pipeline.required "access_token" Decode.string
        |> Pipeline.required "expires_in" Decode.int
        |> Pipeline.required "refresh_token" Decode.string
        |> Pipeline.required "token_type" Decode.string


videoUploadedDecoder : Decode.Decoder VideoUploaded
videoUploadedDecoder =
    Decode.field "video"
        (Decode.succeed VideoUploaded
            |> Pipeline.required "id" Decode.int
            |> Pipeline.required "uuid" Decode.string
        )


type alias Channel =
    Int


videoChannelDecoder : Decode.Decoder Channel
videoChannelDecoder =
    Decode.succeed identity
        |> Pipeline.required "id" Decode.int


videoChannelListDecoder : Decode.Decoder (List Channel)
videoChannelListDecoder =
    Decode.list videoChannelDecoder


videoChannelIDDecoder : Decode.Decoder Channel
videoChannelIDDecoder =
    videoChannelListDecoder
        |> Decode.andThen
            (\channelList ->
                -- We're only interested in the first channel
                case List.head channelList of
                    Just channelID ->
                        Decode.succeed channelID

                    Nothing ->
                        Decode.fail "pas de chaîne trouvée"
            )


userInfoDecoder : Decode.Decoder PartialUserInfo
userInfoDecoder =
    Decode.succeed PartialUserInfo
        |> Pipeline.required "username" Decode.string
        |> Pipeline.required "videoChannels" videoChannelIDDecoder


playlistDecoder : Decode.Decoder Playlist
playlistDecoder =
    Decode.succeed Playlist
        |> Pipeline.required "id" Decode.int
        |> Pipeline.required "uuid" Decode.string
        |> Pipeline.required "displayName" Decode.string


commentDecoder : Decode.Decoder Comment
commentDecoder =
    Decode.succeed Comment
        |> Pipeline.required "id" Decode.int
        |> Pipeline.required "text" Decode.string
        |> Pipeline.required "videoId" Decode.int
        |> Pipeline.required "createdAt" Decode.string
        |> Pipeline.required "updatedAt" Decode.string
        |> Pipeline.required "account" accountDecoder


commentListDecoder : Decode.Decoder (List Comment)
commentListDecoder =
    Decode.field "data" (Decode.list commentDecoder)


alternateCommentDecoder : Decode.Decoder Comment
alternateCommentDecoder =
    Decode.succeed Comment
        |> Pipeline.required "id" Decode.int
        |> Pipeline.required "text" Decode.string
        |> Pipeline.required "videoId" Decode.int
        |> Pipeline.required "createdAt" Decode.string
        |> Pipeline.required "updatedAt" Decode.string
        |> Pipeline.required "Account" alternateAccountDecoder


alternateCommentListDecoder : Decode.Decoder (List Comment)
alternateCommentListDecoder =
    Decode.field "data" (Decode.list alternateCommentDecoder)



---- ENCODERS ----


encodeUserInfo : UserInfo -> Encode.Value
encodeUserInfo userInfo =
    Encode.object
        [ ( "username", Encode.string userInfo.username )
        , ( "channelID", Encode.int userInfo.channelID )
        , ( "playlistID", Encode.int userInfo.playlistID )
        ]


encodeUserToken : UserToken -> Encode.Value
encodeUserToken userToken =
    Encode.object
        [ ( "access_token", Encode.string userToken.access_token )
        , ( "expires_in", Encode.int userToken.expires_in )
        , ( "refresh_token", Encode.string userToken.refresh_token )
        , ( "token_type", Encode.string userToken.token_type )
        ]


encodeComment : String -> Encode.Value
encodeComment text =
    Encode.object
        [ ( "text", Encode.string text ) ]


encodeNewVideoData : NewVideo -> Encode.Value
encodeNewVideoData video =
    let
        keywords =
            if video.grade /= "" then
                video.grade :: video.keywords

            else
                video.keywords

        encodedKeywords =
            if keywords /= [] then
                [ ( "keywords", encodeKeywords keywords ) ]

            else
                []
    in
    Encode.object
        ([ ( "description", Encode.string video.description )
         , ( "title", Encode.string video.title )
         , ( "grade", Encode.string video.grade )
         ]
            ++ encodedKeywords
        )


encodeKeywords : List String -> Encode.Value
encodeKeywords keywords =
    keywords
        |> Encode.list Encode.string

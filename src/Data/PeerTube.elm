module Data.PeerTube exposing
    ( Account
    , BlacklistedVideo
    , Comment
    , NewVideo
    , RemoteData(..)
    , UserInfo
    , UserToken
    , Video
    , VideoUploaded
    , accountDecoder
    , blacklistedVideoDecoder
    , commentDecoder
    , commentListDecoder
    , dataDecoder
    , emptyNewVideo
    , encodeComment
    , encodeNewVideoData
    , encodeUserInfo
    , encodeUserToken
    , userInfoDecoder
    , userTokenDecoder
    , videoDecoder
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


type alias UserInfo =
    { username : String
    , channelID : Int
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
    , files : List String
    }


type alias BlacklistedVideo =
    { id : Int
    , video : Video
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


emptyNewVideo =
    { description = ""
    , title = ""
    , grade = "CP"
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


type RemoteData a
    = NotRequested
    | Requested
    | Received a
    | Failed String



---- DECODERS ----


dataDecoder : Decode.Decoder (List Video)
dataDecoder =
    Decode.field "data" videoListDecoder


videoListDecoder : Decode.Decoder (List Video)
videoListDecoder =
    Decode.list videoDecoder


accountDecoder : Decode.Decoder Account
accountDecoder =
    Decode.succeed Account
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "displayName" Decode.string
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
        |> Pipeline.optional "files" (Decode.list (Decode.field "fileUrl" Decode.string)) []


blacklistedVideoDecoder : Decode.Decoder BlacklistedVideo
blacklistedVideoDecoder =
    Decode.succeed BlacklistedVideo
        |> Pipeline.required "id" Decode.int
        |> Pipeline.required "video" videoDecoder


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


userInfoDecoder : Decode.Decoder UserInfo
userInfoDecoder =
    Decode.succeed UserInfo
        |> Pipeline.required "username" Decode.string
        |> Pipeline.required "videoChannels" videoChannelIDDecoder


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



---- ENCODERS ----


encodeUserInfo : UserInfo -> Encode.Value
encodeUserInfo userInfo =
    Encode.object
        [ ( "username", Encode.string userInfo.username )
        , ( "channelID", Encode.int userInfo.channelID )
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
    Encode.object
        [ ( "description", Encode.string video.description )
        , ( "title", Encode.string video.title )
        , ( "grade", Encode.string video.grade )
        , ( "keywords", encodeKeywords video.keywords )
        ]


encodeKeywords : List String -> Encode.Value
encodeKeywords keywords =
    keywords
        |> Encode.list Encode.string

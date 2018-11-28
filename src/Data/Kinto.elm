module Data.Kinto exposing
    ( Attachment
    , Contact
    , DeletedRecord
    , KintoData(..)
    , NewVideo
    , Video
    , VideoList
    , VideoListData
    , attachmentDecoder
    , contactDecoder
    , decodeContactList
    , decodeVideoList
    , deletedRecordDecoder
    , emptyAttachment
    , emptyContact
    , emptyNewVideo
    , emptyVideo
    , encodeAttachmentData
    , encodeContactData
    , encodeNewVideoData
    , encodeVideoData
    , videoDecoder
    )

import Json.Decode as Decode
import Json.Encode as Encode
import Kinto


type KintoData a
    = NotRequested
    | Requested
    | Received a
    | Failed Kinto.Error


type alias VideoList =
    Kinto.Pager Video


type alias VideoListData =
    KintoData VideoList


type alias DeletedRecord =
    { id : String
    , last_modified : Int
    , deleted : Bool
    }


deletedRecordDecoder : Decode.Decoder DeletedRecord
deletedRecordDecoder =
    Decode.map3 DeletedRecord
        (Decode.field "id" Decode.string)
        (Decode.field "last_modified" Decode.int)
        (Decode.field "deleted" Decode.bool)



---- VIDEO ----


type alias Video =
    { id : String
    , last_modified : Int
    , title : String
    , keywords : List String
    , description : String
    , attachment : Attachment
    , duration : Int
    , thumbnail : String
    }


emptyVideo =
    { id = ""
    , last_modified = 0
    , title = ""
    , keywords = []
    , description = ""
    , attachment = emptyAttachment
    , duration = 0
    , thumbnail = ""
    }


type alias NewVideo =
    { title : String
    , keywords : List String
    , description : String
    }


emptyNewVideo =
    { description = ""
    , title = ""
    , keywords = []
    }


videoDecoder : Decode.Decoder Video
videoDecoder =
    Decode.map8 Video
        (Decode.field "id" Decode.string)
        (Decode.field "last_modified" Decode.int)
        (Decode.field "title" Decode.string)
        (Decode.field "keywords" keywordsDecoder)
        (Decode.field "description" Decode.string)
        (Decode.field "attachment" attachmentDecoder)
        (Decode.field "duration" Decode.int)
        (Decode.field "thumbnail" Decode.string)


keywordsDecoder : Decode.Decoder (List String)
keywordsDecoder =
    Decode.oneOf
        [ Decode.list Decode.string
        , Decode.string
            |> Decode.andThen (\keyword -> Decode.succeed [ keyword ])
        ]


encodeKeywords : List String -> Encode.Value
encodeKeywords keywords =
    Encode.list Encode.string keywords


decodeVideoList : Decode.Value -> Result Decode.Error (List Video)
decodeVideoList =
    Decode.decodeValue <|
        Decode.list videoDecoder


encodeNewVideoData : NewVideo -> Encode.Value
encodeNewVideoData video =
    Encode.object
        [ ( "description", Encode.string video.description )
        , ( "title", Encode.string video.title )
        , ( "keywords", encodeKeywords video.keywords )
        ]


encodeVideoData : Video -> Encode.Value
encodeVideoData video =
    Encode.object
        [ ( "id", Encode.string video.id )
        , ( "last_modified", Encode.int video.last_modified )
        , ( "title", Encode.string video.title )
        , ( "keywords", encodeKeywords video.keywords )
        , ( "description", Encode.string video.description )
        , ( "attachment", encodeAttachmentData video.attachment )
        , ( "duration", Encode.int video.duration )
        , ( "thumbnail", Encode.string video.thumbnail )
        ]



---- ATTACHMENT ----


type alias Attachment =
    { filename : String
    , hash : String
    , location : String
    , mimetype : String
    , size : Int
    }


emptyAttachment =
    { filename = ""
    , hash = ""
    , location = ""
    , mimetype = ""
    , size = 0
    }


attachmentDecoder : Decode.Decoder Attachment
attachmentDecoder =
    Decode.map5 Attachment
        (Decode.field "filename" Decode.string)
        (Decode.field "hash" Decode.string)
        (Decode.field "location" Decode.string)
        (Decode.field "mimetype" Decode.string)
        (Decode.field "size" Decode.int)


encodeAttachmentData : Attachment -> Encode.Value
encodeAttachmentData attachment =
    Encode.object
        [ ( "filename", Encode.string attachment.filename )
        , ( "hash", Encode.string attachment.hash )
        , ( "location", Encode.string attachment.location )
        , ( "mimetype", Encode.string attachment.mimetype )
        , ( "size", Encode.int attachment.size )
        ]



---- CONTACT ----


type alias Contact =
    { id : String
    , name : String
    , email : String
    , role : String
    }


emptyContact =
    { id = ""
    , name = ""
    , email = ""
    , role = ""
    }


contactDecoder : Decode.Decoder Contact
contactDecoder =
    Decode.map4 Contact
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.field "role" Decode.string)


decodeContactList : Decode.Value -> Result Decode.Error (List Contact)
decodeContactList =
    Decode.decodeValue <|
        Decode.list contactDecoder


encodeContactData : Contact -> Encode.Value
encodeContactData contact =
    Encode.object
        [ ( "name", Encode.string contact.name )
        , ( "email", Encode.string contact.email )
        , ( "role", Encode.string contact.role )
        ]

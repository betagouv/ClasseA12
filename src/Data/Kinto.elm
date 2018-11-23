module Data.Kinto exposing
    ( Attachment
    , Contact
    , DeletedRecord
    , KintoData(..)
    , NewVideo
    , Video
    , attachmentDecoder
    , contactDecoder
    , decodeContactList
    , decodeVideoList
    , deletedRecordDecoder
    , emptyContact
    , emptyNewVideo
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
    , keywords : String
    , description : String
    , attachment : Attachment
    }


type alias NewVideo =
    { title : String
    , keywords : String
    , description : String
    }


emptyNewVideo =
    { description = ""
    , title = ""
    , keywords = ""
    }


videoDecoder : Decode.Decoder Video
videoDecoder =
    Decode.map6 Video
        (Decode.field "id" Decode.string)
        (Decode.field "last_modified" Decode.int)
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "keywords" Decode.string)
        (Decode.field "attachment" attachmentDecoder)


decodeVideoList : Decode.Value -> Result Decode.Error (List Video)
decodeVideoList =
    Decode.decodeValue <|
        Decode.list videoDecoder


encodeNewVideoData : NewVideo -> Encode.Value
encodeNewVideoData video =
    Encode.object
        [ ( "description", Encode.string video.description )
        , ( "title", Encode.string video.title )
        , ( "keywords", Encode.string video.keywords )
        ]


encodeVideoData : Video -> Encode.Value
encodeVideoData video =
    Encode.object
        [ ( "id", Encode.string video.id )
        , ( "last_modified", Encode.int video.last_modified )
        , ( "title", Encode.string video.title )
        , ( "keywords", Encode.string video.keywords )
        , ( "description", Encode.string video.description )
        , ( "attachment", encodeAttachmentData video.attachment )
        ]



---- ATTACHMENT ----


type alias Attachment =
    { filename : String
    , hash : String
    , location : String
    , mimetype : String
    , size : Int
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

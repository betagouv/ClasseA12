module Data.Kinto exposing
    ( Attachment
    , Contact
    , KintoData(..)
    , Video
    , attachmentDecoder
    , contactDecoder
    , decodeContactList
    , decodeVideoList
    , emptyContact
    , emptyVideo
    , encodeContactData
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



---- VIDEO ----


type alias Video =
    { id : String
    , last_modified : Int
    , title : String
    , keywords : String
    , description : String
    , attachment : Maybe Attachment
    }


emptyVideo =
    { id = ""
    , last_modified = 0
    , description = ""
    , title = ""
    , keywords = ""
    , attachment = Nothing
    }


videoDecoder : Decode.Decoder Video
videoDecoder =
    Decode.map6 Video
        (Decode.field "id" Decode.string)
        (Decode.field "last_modified" Decode.int)
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "keywords" Decode.string)
        (Decode.maybe (Decode.field "attachment" attachmentDecoder))


decodeVideoList : Decode.Value -> Result Decode.Error (List Video)
decodeVideoList =
    Decode.decodeValue <|
        Decode.list videoDecoder


encodeVideoData : Video -> Encode.Value
encodeVideoData video =
    Encode.object
        [ ( "description", Encode.string video.description )
        , ( "title", Encode.string video.title )
        , ( "keywords", Encode.string video.keywords )
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

module Data.Kinto exposing
    ( Attachment
    , Contact
    , ContactList
    , ContactListData
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
    , keywordList
    , videoDecoder
    )

import Dict
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Kinto
import Time


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
    Decode.succeed DeletedRecord
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "last_modified" Decode.int
        |> Pipeline.required "deleted" Decode.bool



---- VIDEO ----


type alias Video =
    { id : String
    , last_modified : Int
    , title : String
    , grade : String
    , keywords : List String
    , description : String
    , attachment : Attachment
    , duration : Int
    , thumbnail : String
    , creation_date : Time.Posix
    }


emptyVideo =
    { id = ""
    , last_modified = 0
    , title = ""
    , grade = "CP"
    , keywords = []
    , description = ""
    , attachment = emptyAttachment
    , duration = 0
    , thumbnail = ""
    , creation_date = Time.millisToPosix 0
    }


type alias NewVideo =
    { title : String
    , grade : String
    , keywords : List String
    , description : String
    , creation_date : Time.Posix
    }


emptyNewVideo =
    { description = ""
    , title = ""
    , grade = "CP"
    , keywords = []
    , creation_date = Time.millisToPosix 0
    }


videoDecoder : Decode.Decoder Video
videoDecoder =
    Decode.succeed Video
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "last_modified" Decode.int
        |> Pipeline.required "title" Decode.string
        |> Pipeline.required "grade" Decode.string
        |> Pipeline.required "keywords" keywordsDecoder
        |> Pipeline.required "description" Decode.string
        |> Pipeline.required "attachment" attachmentDecoder
        |> Pipeline.required "duration" Decode.int
        |> Pipeline.required "thumbnail" Decode.string
        |> Pipeline.optional "creation_date" posixDecoder (Time.millisToPosix 0)


posixDecoder : Decode.Decoder Time.Posix
posixDecoder =
    Decode.int
        |> Decode.map Time.millisToPosix


keywordsDecoder : Decode.Decoder (List String)
keywordsDecoder =
    Decode.list Decode.string


encodePosix : Time.Posix -> Encode.Value
encodePosix posix =
    Time.posixToMillis posix
        |> Encode.int


encodeKeywords : List String -> Encode.Value
encodeKeywords keywords =
    keywords
        |> Encode.list Encode.string


decodeVideoList : Decode.Value -> Result Decode.Error (List Video)
decodeVideoList =
    Decode.decodeValue <|
        Decode.list videoDecoder


encodeNewVideoData : NewVideo -> Encode.Value
encodeNewVideoData video =
    Encode.object
        [ ( "description", Encode.string video.description )
        , ( "title", Encode.string video.title )
        , ( "grade", Encode.string video.grade )
        , ( "keywords", encodeKeywords video.keywords )
        , ( "creation_date", encodePosix video.creation_date )
        ]


encodeVideoData : Video -> Encode.Value
encodeVideoData video =
    Encode.object
        [ ( "id", Encode.string video.id )
        , ( "last_modified", Encode.int video.last_modified )
        , ( "title", Encode.string video.title )
        , ( "grade", Encode.string video.grade )
        , ( "keywords", encodeKeywords video.keywords )
        , ( "description", Encode.string video.description )
        , ( "attachment", encodeAttachmentData video.attachment )
        , ( "duration", Encode.int video.duration )
        , ( "thumbnail", Encode.string video.thumbnail )
        , ( "creation_date", encodePosix video.creation_date )
        ]


keywordList : List ( String, String )
keywordList =
    [ ( "Français", "Lecture / écriture / oral / compréhension / production d’écrit / grammaire / conjugaison / vocabulaire / orthographe / album" )
    , ( "Mathématiques", "numération / calcul / résolution de problème / mesure / géométrie / jeux" )
    , ( "Questionner le monde", "temps / espace" )
    , ( "Arts", "Education musicale / éducation plastiques" )
    , ( "Éducation physique et sportive", "" )
    , ( "Enseignement moral et civique", "" )
    , ( "Gestion de classe", "différenciation / autonomie / concentration / coopération / aménagement de classe / affichage / gestion des élèves / plan de travail / atelier / sortie / cahier" )
    , ( "Le projet Classe à 12", "tutoriel / témoignage" )
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
    Decode.succeed Attachment
        |> Pipeline.required "filename" Decode.string
        |> Pipeline.required "hash" Decode.string
        |> Pipeline.required "location" Decode.string
        |> Pipeline.required "mimetype" Decode.string
        |> Pipeline.required "size" Decode.int


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


type alias ContactList =
    Kinto.Pager Contact


type alias ContactListData =
    KintoData ContactList


emptyContact =
    { id = ""
    , name = ""
    , email = ""
    , role = ""
    }


contactDecoder : Decode.Decoder Contact
contactDecoder =
    Decode.succeed Contact
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "email" Decode.string
        |> Pipeline.required "role" Decode.string


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

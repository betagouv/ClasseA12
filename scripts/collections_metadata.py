"""Collections data and permissions."""

import kinto_http
import copy

VIDEOS_COLLECTIONS_METADATA = {
    "permissions": {"write": ["account:classea12admin"]},
    "data": {
        "sort": "-creation_date,-last_modified",
        "schema": {
            "type": "object",
            "properties": {
                "title": {
                    "type": "string",
                    "title": "Titre",
                    "description": "Titre de la vid\u00e9o",
                },
                "duration": {
                    "type": "number",
                    "title": "Duration",
                    "description": "Duration of the video in seconds",
                },
                "keywords": {
                    "type": "array",
                    "items": {
                        "enum": [
                            "Am\u00e9nagement classe",
                            "Am\u00e9nagement classe - Mobilier",
                            "Am\u00e9nagement classe - Rangement",
                            "Tutoriel",
                            "\u00c9valuation",
                            "T\u00e9moignages",
                            "T\u00e9moignages - conseils",
                            "Fran\u00e7ais",
                            "Fran\u00e7ais - Lecture",
                            "Fran\u00e7ais - Production d'\u00e9crits",
                            "Fran\u00e7ais - Oral",
                            "Fran\u00e7ais - Po\u00e9sie",
                            "Autonomie",
                            "\u00c9ducation musicale",
                            "Graphisme",
                            "Co-\u00e9ducation",
                            "Mathématiques",
                            "Mathématiques - Calcul",
                            "Mathématiques - Résolution de problèmes",
                            "EMC",
                            "Programmation",
                            "CP",
                            "CE1",
                        ],
                        "type": "string",
                    },
                    "title": "Mots cl\u00e9s",
                    "description": "Mots cl\u00e9s, th\u00e9matique...",
                    "uniqueItems": True,
                },
                "thumbnail": {
                    "type": "string",
                    "title": "Thumbnail",
                    "description": "Link to a thumbnail for this video",
                },
                "description": {
                    "type": "string",
                    "title": "Description",
                    "description": "Description du contenu de la vid\u00e9o",
                },
                "creation_date": {
                    "type": "number",
                    "title": "Date de cr\u00e9ation",
                    "description": "Date d'envoi de la vid\u00e9o",
                },
            },
        },
        "uiSchema": {
            "ui:order": [
                "title",
                "keywords",
                "description",
                "duration",
                "thumbnail",
                "creation_date",
            ],
            "description": {"ui:widget": "textarea", "ui:options": {"rows": 5}},
        },
        "attachment": {"enabled": True, "required": False},
        "cache_expires": 0,
        "displayFields": [
            "title",
            "keywords",
            "description",
            "duration",
            "creation_date",
        ],
    },
}

CONTACTS_METADATA = {
    "permissions": {
        "read": ["account:classea12admin"],
        "record:create": ["system.Authenticated", "account:classea12admin"],
        "write": ["account:classea12admin"],
    },
    "data": {
        "sort": "name",
        "schema": {
            "type": "object",
            "properties": {
                "name": {
                    "type": "string",
                    "title": "Name",
                    "description": "Name of the contact",
                },
                "role": {
                    "enum": ["CP", "CE1", "Formateur"],
                    "type": "string",
                    "title": "Role",
                    "description": "Role of the contact",
                },
                "email": {
                    "type": "string",
                    "title": "Email",
                    "description": "Email of the contact",
                },
            },
        },
        "uiSchema": {"ui:order": ["name", "email", "role"]},
        "attachment": {"enabled": False, "required": False},
        "cache_expires": 0,
        "displayFields": ["name", "email", "role"],
        "id": "contacts",
    },
}

THUMBNAILS_METADATA = {
    "permissions": {
        "write": ["account:classea12admin"],
        "record:create": ["system.Authenticated"],
    },
    "data": {
        "sort": "-last_modified",
        "schema": {
            "type": "object",
            "properties": {
                "for": {
                    "type": "string",
                    "title": "For",
                    "description": "Record ID de la video pour cette miniature",
                }
            },
        },
        "uiSchema": {"ui:order": ["for"]},
        "attachment": {"enabled": True, "required": False},
        "cache_expires": 0,
        "displayFields": ["for"],
        "id": "thumbnails",
    },
}


def update_upcoming(client):
    data = copy.deepcopy(VIDEOS_COLLECTIONS_METADATA["data"])
    data["id"] = "upcoming"
    permissions = copy.deepcopy(VIDEOS_COLLECTIONS_METADATA["permissions"])
    permissions["record:create"] = ["system.Authenticated"]

    client.update_collection(bucket="classea12", data=data, permissions=permissions)


def update_videos(client):
    data = copy.deepcopy(VIDEOS_COLLECTIONS_METADATA["data"])
    data["id"] = "videos"
    permissions = copy.deepcopy(VIDEOS_COLLECTIONS_METADATA["permissions"])
    permissions["read"] = ["system.Everyone"]

    client.update_collection(bucket="classea12", data=data, permissions=permissions)


def update_contacts(client):
    client.update_collection(
        bucket="classea12",
        data=CONTACTS_METADATA["data"],
        permissions=CONTACTS_METADATA["permissions"],
    )


def update_thumbnails(client):
    client.update_collection(
        bucket="classea12",
        data=THUMBNAILS_METADATA["data"],
        permissions=THUMBNAILS_METADATA["permissions"],
    )

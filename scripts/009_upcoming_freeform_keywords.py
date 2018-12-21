"""Change from the previous keywords to the new ones.

For each `upcoming` record, switch from one of the previous keywords to the new ones.

Requirements: kinto_http

$ pip install kinto_http

To use: run the following

$ python 009_upcoming_freeform_keywords.py --auth "<admin login>:<admin password>" --server "https://<kinto server>/v1/"

"""

import base64
import json
import os
import pprint

from kinto_http import cli_utils
from kinto_http.exceptions import KintoException

import collections_metadata

DEFAULT_BUCKET = "classea12"
DEFAULT_COLLECTION = "upcoming"

OLD_TO_NEW = {
    "Aménagement classe": ["Gestion de classe"],
    "Aménagement classe - Mobilier": ["Gestion de classe", "Mobilier"],
    "Aménagement classe - Rangement": ["Gestion de classe", "Rangement"],
    "Tutoriel": ["Le projet Classe à 12"],
    "Évaluation": ["Gestion de classe"],
    "Témoignages": ["Le projet Classe à 12"],
    "Témoignages - conseils": ["Le projet Classe à 12", "Conseils"],
    "Français": ["Français"],
    "Français - Lecture": ["Français", "Lecture"],
    "Français - Production d'écrits": ["Français", "Production d'écrits"],
    "Français - Oral": ["Français", "Oral"],
    "Français - Poésie": ["Français", "Poésie"],
    "Autonomie": ["Gestion de classe"],
    "Éducation musicale": ["Arts", "Éducation musicale"],
    "Graphisme": ["Arts", "Éducation plastique"],
    "Co-éducation": ["Gestion de classe"],
    "Mathématiques": ["Mathématiques"],
    "Mathématiques - Calcul": ["Mathématiques", "Calcul"],
    "Mathématiques - Résolution de problèmes": [
        "Mathématiques",
        "Résolution de problèmes",
    ],
    "EMC": ["Enseignement moral et civique"],
    "Programmation": ["Mathématiques", "Programmation"],
}


def switch_keywords(client, videos):
    for video in videos:
        old_keywords = video["keywords"]
        new_keywords = []
        for old_keyword in old_keywords:
            new_keyword_list = OLD_TO_NEW.get(old_keyword, [old_keyword])
            new_keywords += new_keyword_list
        new_keywords = list(set(new_keywords))
        print("New list of keywords for video", video["id"], ":", new_keywords)
        video["keywords"] = new_keywords
        client.update_record(data=video)


def main():
    parser = cli_utils.add_parser_options(
        description="Switch from the previous keywords to the new ones for the `upcoming` collection",
        default_bucket=DEFAULT_BUCKET,
        default_collection=DEFAULT_COLLECTION,
    )

    args = parser.parse_args()

    client = cli_utils.create_client_from_args(args)

    try:
        client.create_bucket(if_not_exists=True)
        client.create_collection(if_not_exists=True)
    except KintoException:
        # Fail silently in case of 403
        pass

    collections_metadata.update_upcoming(client)

    print("Fetching records")
    videos = client.get_records()
    filtered_videos = [
        video for video in videos if "keywords" in video and video["keywords"]
    ]
    print("Found", len(filtered_videos), "videos with keywords")
    print("Updating records")
    switch_keywords(client, filtered_videos)


if __name__ == "__main__":
    main()

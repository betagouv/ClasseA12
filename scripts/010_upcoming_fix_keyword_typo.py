"""Fix a keyword typo: "Éducation plastique" -> "Éducation artistique".

Requirements: kinto_http

$ pip install kinto_http

To use: run the following

$ python 010_upcoming_fix_keyword_typo.py --auth "<admin login>:<admin password>" --server "https://<kinto server>/v1/"

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


def fix_typo(client, videos):
    for video in videos:
        keywords = [
            keyword for keyword in video["keywords"] if keyword != "Éducation plastique"
        ]
        keywords += ["Éducation artistique"]
        new_keywords = list(set(keywords))
        print("New list of keywords for video", video["id"], ":", new_keywords)
        video["keywords"] = new_keywords
        client.update_record(data=video)


def main():
    parser = cli_utils.add_parser_options(
        description="Fix a keyword typo: 'Éducation plastique' -> 'Éducation artistique'.",
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
        video
        for video in videos
        if "keywords" in video
        and video["keywords"]
        and "Éducation plastique" in video["keywords"]
    ]
    print("Found", len(filtered_videos), "videos with the typo'ed keyword")
    print("Updating records")
    fix_typo(client, filtered_videos)


if __name__ == "__main__":
    main()

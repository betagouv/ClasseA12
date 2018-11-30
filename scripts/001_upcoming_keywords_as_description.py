"""Migrate the `upcoming` records to have keywords appended to their description.

For each `upcoming` record, if the "keywords" field is present, add a
"keywords: <the keywords>" line to their description.
The rationale is that those videos were created at a time when keywords
weren't really a thing, and people just put words or description in them.

Requirements: kinto_http

$ pip install kinto_http

To use: run the following

$ python 001_upcoming_keywords_as_description.py --auth "<admin login>:<admin password>"

"""

import base64
import json
import os
import pprint
import urllib.request
import time
import datetime

from kinto_http import cli_utils
from kinto_http.exceptions import KintoException

DEFAULT_SERVER = "https://kinto.agopian.info/v1/"
DEFAULT_BUCKET = "classea12"
DEFAULT_COLLECTION = "upcoming"


def move_keywords_to_description(videos):
    for video in videos:
        keywords = video["keywords"]
        if keywords != "":
            video["description"] = video["description"] + "\nMots clé : " + keywords
        # This will also convert the empty keywords ("") to be an empty array.
        video["keywords"] = []


def update_videos(client, videos):
    for video in videos:
        print("Updating video", video["id"], "with description", video["description"])
        client.update_record(data=video)


def main():
    parser = cli_utils.add_parser_options(
        description="Move the keywords from the `upcoming` records to their description",
        default_server=DEFAULT_SERVER,
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

    print("Fetching records")
    videos = client.get_records()
    print("Found", len(videos), "videos")
    move_keywords_to_description(videos)
    print("Updating records")
    update_videos(client, videos)


if __name__ == "__main__":
    main()

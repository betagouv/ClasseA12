"""Migrate the `upcoming` records to have a creation date.

For each `upcoming` record, copy the `last_modified` date as the `creation_date`.

Requirements: kinto_http

$ pip install kinto_http

To use: run the following

$ python 002_upcoming_add_creation_date.py --auth "<admin login>:<admin password>"

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

DEFAULT_SERVER = "https://kinto.classea12.beta.gouv.fr/v1/"
DEFAULT_BUCKET = "classea12"
DEFAULT_COLLECTION = "upcoming"


def add_creation_date(videos):
    for video in videos:
        video["creation_date"] = video["last_modified"]


def update_videos(client, videos):
    for video in videos:
        print(
            "Updating video", video["id"], "with creation date", video["creation_date"]
        )
        client.update_record(data=video)


def main():
    parser = cli_utils.add_parser_options(
        description="Add a creation_date field to the `upcoming` records",
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
    print("Found", len(videos), "videos, use last_modified date for the creation_date")
    add_creation_date(videos)
    print("Updating records")
    update_videos(client, videos)


if __name__ == "__main__":
    main()

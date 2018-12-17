"""Add a `grade` field to the `upcoming` records.

For each `upcoming` record, add a `grade` field and set it by default to `CP`.

Requirements: kinto_http

$ pip install kinto_http

To use: run the following

$ python 007_upcoming_add_grade.py --auth "<admin login>:<admin password>" --server "https://<kinto server>/v1/"

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


def add_grades(client, videos):
    for video in videos:
        print("Adding a grade for video", video["id"])
        video["grade"] = "CP"
        client.update_record(data=video)


def main():
    parser = cli_utils.add_parser_options(
        description="Add a `grade` field to the `upcoming` collection",
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
    filtered_videos = [video for video in videos if "grade" not in video.keys()]
    print("Found", len(filtered_videos), "videos without a grade")
    print("Updating records")
    add_grades(client, filtered_videos)


if __name__ == "__main__":
    main()

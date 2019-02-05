"""Add a publish date field.

The publish date is set to match the last_modified date.

Requirements: kinto_http

$ pip install kinto_http

To use: run the following

$ python 011_videos_add_publish_date.py --auth "<admin login>:<admin password>" --server "https://<kinto server>/v1/"

"""

import base64
import json
import os
import pprint

from kinto_http import cli_utils
from kinto_http.exceptions import KintoException

import collections_metadata

DEFAULT_BUCKET = "classea12"
DEFAULT_COLLECTION = "videos"


def add_publish_date(client, videos):
    for video in videos:
        print("Publish date for video", video["id"], ":", video["last_modified"])
        video["publish_date"] = video["last_modified"]
        client.update_record(data=video)


def main():
    parser = cli_utils.add_parser_options(
        description="Add a publish_date",
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

    collections_metadata.update_videos(client)

    print("Fetching records")
    videos = client.get_records()
    filtered_videos = [
        video
        for video in videos
        if "publish_date" not in video or video["publish_date"] == 0
    ]
    print("Found", len(filtered_videos), "videos with no publish date")
    print("Updating records")
    add_publish_date(client, filtered_videos)


if __name__ == "__main__":
    main()

"""Migrate the `videos` records to have keywords as an array of strings,
instead of a single string.

For each `videos` record, if the "keywords" field is a string, change it to
an array with this string.

Requirements: kinto_http

$ pip install kinto_http

To use: run the following

$ python 001_videos_keywords_as_array.py --auth "<admin login>:<admin password>"

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
DEFAULT_COLLECTION = "videos"


def change_keywords_to_array(videos):
    for video in videos:
        keyword = video["keywords"]
        if keyword != "":
            video["keywords"] = [keyword]
        else:
            video["keywords"] = []


def update_videos(client, videos):
    for video in videos:
        print("Updating video", video["id"], "with keywords", video["keywords"])
        client.update_record(data=video)


def main():
    parser = cli_utils.add_parser_options(
        description="Change the videos records 'keywords as a single string' to an array of strings",
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
    videos_with_string_keywords = [
        video for video in videos if type(video["keywords"]) == str
    ]
    print(
        "Found",
        len(videos_with_string_keywords),
        "videos which need their keywords changed to an array",
    )
    change_keywords_to_array(videos_with_string_keywords)
    print("Updating records")
    update_videos(client, videos_with_string_keywords)


if __name__ == "__main__":
    main()

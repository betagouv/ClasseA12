"""Migrate the `videos` records to have a creation date.

For each `videos` record, run a GET on the vimeo API page to retrieve the `upload_date`.
If the GET returns with a 404, it means it's not a video downloaded from
vimeo, in which case use the `last_modification` date.

Requirements: kinto_http

$ pip install kinto_http

To use: run the following

$ python 002_videos_add_creation_date.py --auth "<admin login>:<admin password>"

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


def add_creation_date(videos):
    for video in videos:
        video_filename = video["attachment"]["filename"]
        vimeo_id = video_filename.replace(".mp4", "")
        vimeo_data_url = f"https://vimeo.com/api/v2/video/{vimeo_id}.json"
        try:
            vimeo_data = urllib.request.urlopen(vimeo_data_url)
        except urllib.error.HTTPError:
            print("Error while retrieving vimeo data at", vimeo_data_url)
            continue

        vimeo_json = json.loads(vimeo_data.read())[0]
        creation_date_str = vimeo_json["upload_date"]
        day = datetime.datetime.strptime(creation_date_str, "%Y-%m-%d %H:%M:%S")
        creation_date_timestamp = round(
            time.mktime(day.timetuple()) * 1000
        )  # in milliseconds
        video["creation_date"] = creation_date_timestamp


def update_videos(client, videos):
    for video in videos:
        print(
            "Updating video", video["id"], "with creation date", video["creation_date"]
        )
        client.update_record(data=video)


def main():
    parser = cli_utils.add_parser_options(
        description="Add a creation_date field to the `videos` records",
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
    print("Found", len(videos), "videos, get creation dates from vimeo")
    add_creation_date(videos)
    print("Updating records")
    update_videos(client, videos)


if __name__ == "__main__":
    main()

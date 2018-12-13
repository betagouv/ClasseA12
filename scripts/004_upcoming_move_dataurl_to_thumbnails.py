"""Migrate the thumbnails from the `upcoming` records to the thumbnails collection.

For each `upcoming` record, store the thumbnail data (stored as a data URL in
the database) as an attachment on a record created in the `thumbnails`
collection.

Requirements: kinto_http

$ pip install kinto_http

To use: run the following

$ python 004_upcoming_move_dataurl_to_thumbnails.py --auth "<admin login>:<admin password>"

"""

import base64
import json
import os
import pprint
import urllib.request
import time
import datetime
import urllib.request
import uuid
import mimetypes

from kinto_http import cli_utils
from kinto_http.exceptions import KintoException

import collections_metadata

DEFAULT_SERVER = "https://kinto.classea12.beta.gouv.fr/v1/"
DEFAULT_BUCKET = "classea12"
DEFAULT_COLLECTION = "upcoming"


def upload_thumbnails(client, videos):
    for video in videos:
        # Save the thumbnail data URL as a real file on disk.
        filename, headers = urllib.request.urlretrieve(video["thumbnail"])
        content_type = headers.get_content_type()
        # Upload the thumbnail as an attachment.
        extension = mimetypes.guess_extension(content_type)
        files = [
            (
                "attachment",
                (f"{filename}{extension}", open(filename, "rb"), content_type),
            )
        ]

        data = {"for": video["id"]}
        record_id = str(uuid.uuid4())
        record_uri = client.get_endpoint("record", id=record_id)
        attachment_uri = "%s/attachment" % record_uri
        # The client points to the "upcoming" collection but we want to upload to the thumbnails collection.
        attachment_uri = attachment_uri.replace("upcoming", "thumbnails")

        try:
            thumbnail, _ = client.session.request(
                method="post",
                endpoint=attachment_uri,
                files=files,
                data=json.dumps(data),
            )
        except KintoException as e:
            print(filename, "error during upload.", e)

        # Update the video's thumbnail.
        video["thumbnail"] = thumbnail["location"]


def update_videos(client, videos):
    for video in videos:
        print(
            "Updating video", video["id"], "with thumbnail location", video["thumbnail"]
        )
        client.update_record(data=video)


def main():
    parser = cli_utils.add_parser_options(
        description="Move the thumbnails to attachments in the `thumbnails` collection",
        default_server=DEFAULT_SERVER,
        default_bucket=DEFAULT_BUCKET,
        default_collection=DEFAULT_COLLECTION,
    )

    args = parser.parse_args()

    client = cli_utils.create_client_from_args(args)

    collections_metadata.update_thumbnails(client)

    try:
        client.create_bucket(if_not_exists=True)
        client.create_collection(if_not_exists=True)
    except KintoException:
        # Fail silently in case of 403
        pass

    print("Fetching records")
    videos = client.get_records()
    filtered_videos = [
        video for video in videos if video["thumbnail"].startswith("data:")
    ]
    print(
        "Found", len(filtered_videos), "videos, upload their thumbnails as attachments"
    )
    upload_thumbnails(client, filtered_videos)
    print("Updating records")
    update_videos(client, filtered_videos)


if __name__ == "__main__":
    main()

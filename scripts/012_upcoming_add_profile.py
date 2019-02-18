"""Add a profile field.

The profile is set to the provided ID: the ID of the profile created for the classea12admin account.

Requirements: kinto_http

$ pip install kinto_http

To use: run the following

$ python 012_upcoming_add_profile.py --auth "<admin login>:<admin password>" --server "https://<kinto server>/v1/" --profile "<profile id>"

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


def add_profile(client, videos, profile_id):
    for video in videos:
        print("Add the profile for video", video["id"])
        video["profile"] = profile_id
        client.update_record(data=video)


def main():
    parser = cli_utils.add_parser_options(
        description="Add a profile",
        default_bucket=DEFAULT_BUCKET,
        default_collection=DEFAULT_COLLECTION,
    )

    parser.add_argument(
        "--profile",
        dest="profile_id",
        help="Profile ID",
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
    print("Found", len(videos), "videos")
    print("Updating records")
    add_profile(client, videos, args.profile_id)


if __name__ == "__main__":
    main()

"""Update the collections metadata.

Requirements: kinto_http

$ pip install kinto_http

To use: run the following

$ python update_collections_metadata.py --auth "<admin login>:<admin password>" --server "https://<kinto server>/v1/"

"""

import base64
import json
import os
import pprint
import urllib.request

from kinto_http import cli_utils
from kinto_http.exceptions import KintoException

import collections_metadata

DEFAULT_BUCKET = "classea12"


def main():
    parser = cli_utils.add_parser_options(
        description="Update the collections metadata", default_bucket=DEFAULT_BUCKET
    )

    args = parser.parse_args()

    client = cli_utils.create_client_from_args(args)

    print("Updating the `upcoming` collection")
    collections_metadata.update_upcoming(client)

    print("Updating the `videos` collection")
    collections_metadata.update_videos(client)

    print("Updating the `contacts` collection")
    collections_metadata.update_contacts(client)

    print("Updating the `thumbnails` collection")
    collections_metadata.update_thumbnails(client)

    print("Updating the `profiles` collection")
    collections_metadata.update_profiles(client)

    print("Updating the `comments` collection")
    collections_metadata.update_comments(client)


if __name__ == "__main__":
    main()

"""Migrate the `videos` attachments records to point to a
videos.classea12.beta.gouv.fr subdomain.

Change the attachments records' location to point to a proper static website
(videos.classea12.beta.gouv.fr). This will have the added benefit of using a
"standard static files apache server", which is configured by default to
honor `byte-range requests` which are mandatory to have [videos playable on
Safari](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/CreatingVideoforSafarioniPhone/CreatingVideoforSafarioniPhone.html#//apple_ref/doc/uid/TP40006514-SW6).

Requirements: kinto_http psycopg2

$ pip install kinto_http psycopg2

To use: run the following

$ python 003_videos_from_videos_subdomain.py --auth "<admin login>:<admin password>" --pg "host=<host> dbname=<db name> user=<username> password=<password>"

"""

import base64
import json
import os
import pprint
import urllib.request
import time
import datetime
import psycopg2

from kinto_http import cli_utils
from kinto_http.exceptions import KintoException

DEFAULT_SERVER = "https://kinto.classea12.beta.gouv.fr/v1/"
DEFAULT_BUCKET = "classea12"
DEFAULT_COLLECTION = "videos"


def change_location(videos):
    for video in videos:
        video_location = video["attachment"]["location"]
        new_location = video_location.replace(
            "https://kinto.https://kinto.classea12.beta.gouv.fr/v1/.info/attachments/",
            "https://videos.classea12.beta.gouv.fr/",
        )
        video["attachment"]["location"] = new_location


def update_videos(client, cursor, videos):
    for video in videos:
        print(
            "Updating video",
            video["id"],
            "with location",
            video["attachment"]["location"],
        )
        # The kinto_http client doesn't allow us to modify an attachment
        # record, so we update it using a raw sql query.

        # Query the database and obtain data as Python objects
        cursor.execute(
            """
        UPDATE
            "public"."records"
        SET
            "data" = %s
        WHERE
            "id" = %s
        """,
            (json.dumps(video), video["id"]),
        )


def main():
    parser = cli_utils.add_parser_options(
        description="Change the location of the `videos` records attachments",
        default_server=DEFAULT_SERVER,
        default_bucket=DEFAULT_BUCKET,
        default_collection=DEFAULT_COLLECTION,
    )

    parser.add_argument(
        "--pg",
        dest="connection_string",
        help="""Connection string to the postgresql database:
        "host=<host> dbname=<dbname> user=<username> password=<password>"
        """,
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
    print("Found", len(videos), "videos, change their attachment's location")
    change_location(videos)

    # Connect to an existing database
    conn = psycopg2.connect(args.connection_string)

    # Open a cursor to perform database operations
    cursor = conn.cursor()

    print("Updating records")
    update_videos(client, cursor, videos)

    # Make the changes to the database persistent
    conn.commit()

    # Close communication with the database
    cursor.close()
    conn.close()


if __name__ == "__main__":
    main()

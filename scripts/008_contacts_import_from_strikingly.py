"""Import contacts from strikingly to the `contacts` collection.

Requirements: kinto_http

$ pip install kinto_http

To use: run the following

$ python 008_contacts_import_from_strikingly.py --auth "<admin login>:<admin password>" --server "https://<kinto server>/v1/" <file.csv>

"""

import base64
import json
import os
import pprint
from csv import DictReader

from kinto_http import cli_utils
from kinto_http.exceptions import KintoException

import collections_metadata

DEFAULT_BUCKET = "classea12"
DEFAULT_COLLECTION = "contacts"


def import_contacts(csvfile):
    with open(csvfile, "r") as f:
        csvreader = DictReader(f)
        return list(csvreader)


def add_contacts(client, contacts):
    with client.batch() as batch:
        for contact in contacts:
            print("Adding a contact", contact)
            batch.create_record(data=contact)


def main():
    parser = cli_utils.add_parser_options(
        description="Import contacts from strikingly to the `contacts` collection",
        default_bucket=DEFAULT_BUCKET,
        default_collection=DEFAULT_COLLECTION,
    )

    parser.add_argument(
        "csvfile", action="store", help="CSV file to import the contacts from"
    )

    args = parser.parse_args()

    client = cli_utils.create_client_from_args(args)

    try:
        client.create_bucket(if_not_exists=True)
        client.create_collection(if_not_exists=True)
    except KintoException:
        # Fail silently in case of 403
        pass

    collections_metadata.update_contacts(client)

    print("Importing contacts")
    contacts = import_contacts(args.csvfile)
    print("Found", len(contacts), "contacts to import")
    print("Creating records")
    add_contacts(client, contacts)


if __name__ == "__main__":
    main()

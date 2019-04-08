"""Kinto to Peertube migration script."""

import json
import os
import urllib.request
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import List

import requests
import minicli
from PIL import Image
from progressist import ProgressBar

ROOT = Path(".cache")
KINTO_URL = "https://kinto.classea12.beta.gouv.fr"
PEERTUBE_BASE_URL = os.environ.get("PEERTUBE_URL", "https://peertube.scopyleft.fr")
PEERTUBE_URL = f"{PEERTUBE_BASE_URL}/api/v1"
PEERTUBE_USER = "classea12"
PEERTUBE_PASSWORD = os.environ.get("PEERTUBE_PASSWORD", "")


def urlretrieve(url, dest):
    print("Downloading", url)
    bar = ProgressBar(template="Download |{animation}| {done:B}/{total:B}")
    urllib.request.urlretrieve(url, dest, reporthook=bar.on_urlretrieve)


@dataclass
class Attachment:
    filename: str
    hash: str
    location: str
    mimetype: str
    size: int

    @classmethod
    def get_root(self):
        return ROOT / "attachment"

    def download(self, force=False):
        self.get_root().mkdir(exist_ok=True, parents=True)
        dest = self.get_file()
        if not dest.exists() or force:
            urlretrieve(self.location, dest)

    def get_file(self):
        return self.get_root() / self.hash

    def get_filename(self):
        return self.location.split("/")[-1]


@dataclass
class Video:
    attachment: Attachment
    creation_date: int
    description: str
    duration: int
    grade: str
    id: str
    keywords: List[str]
    last_modified: int
    profile: str
    publish_date: int
    schema: int
    thumbnail: str
    title: str
    peertube_uuid: str = ""

    def __post_init__(self):
        self.attachment = Attachment(**self.attachment)

    def __str__(self):
        return self.title

    @classmethod
    def all(cls):
        for path in cls.get_root().glob("*-meta"):
            yield Video(**json.loads(path.read_text()))

    @classmethod
    def get_root(self):
        return ROOT / "video"

    def persist(self, force=False):
        dest = self.get_root() / f"{self.id}-meta"
        if not dest.exists() or force:
            dest.write_text(json.dumps(asdict(self)))

    def download(self, force=False):
        self.get_root().mkdir(exist_ok=True, parents=True)
        self.persist(force=force)
        dest = self.get_root() / f"{self.id}-thumbnail"
        if not dest.exists() or force:
            urlretrieve(self.thumbnail, dest)
            # PeerTube only accept jpeg.
            Image.open(dest).convert("RGB").save(
                dest, "JPEG", quality=95, subsampling=0
            )
        self.attachment.download(force=force)

    def get_thumbnail_file(self):
        return self.get_root() / f"{self.id}-thumbnail"

    def get_thumbnail_filename(self):
        return self.id + ".jpeg"


@dataclass
class Profile:
    bio: str
    name: str
    schema: int
    id: str
    last_modified: int

    def download(self, force=False):
        root = ROOT / "profile"
        root.mkdir(exist_ok=True, parents=True)
        dest = root / self.id
        if not dest.exists() or force:
            dest.write_text(json.dumps(asdict(self)))


@minicli.cli
def pull(force=False):
    resp = requests.get(f"{KINTO_URL}/v1/buckets/classea12/collections/videos/records")
    videos = resp.json()["data"]
    for raw in videos:
        video = Video(**raw)
        video.download(force=force)
    resp = requests.get(
        f"{KINTO_URL}/v1/buckets/classea12/collections/profiles/records"
    )
    data = resp.json()["data"]
    for raw in data:
        profile = Profile(**raw)
        profile.download(force=force)


def get_token():
    resp = requests.get(f"{PEERTUBE_URL}/oauth-clients/local")
    client_id = resp.json()["client_id"]
    client_secret = resp.json()["client_secret"]
    url = f"{PEERTUBE_URL}/users/token"
    resp = requests.post(
        url,
        data={
            "client_id": client_id,
            "client_secret": client_secret,
            "grant_type": "password",
            "response_type": "code",
            "username": PEERTUBE_USER,
            "password": PEERTUBE_PASSWORD,
        },
    )
    return resp.json()["access_token"]


def get_channel_id(headers):
    resp = requests.get(f"{PEERTUBE_URL}/users/me", headers=headers)
    return resp.json()["videoChannels"][0]["id"]


@minicli.cli
def push(limit=1):
    token = get_token()
    headers = {"Authorization": f"Bearer {token}"}
    channel_id = get_channel_id(headers)
    url = f"{PEERTUBE_URL}/videos/upload"
    count = 0
    for video in Video.all():
        print(video.title, video.id)
        if video.peertube_uuid:
            resp = requests.get(f"{PEERTUBE_URL}/videos/{video.peertube_uuid}")
            if resp.ok:
                print("Video already in the remote server", video.peertube_uuid)
                continue
        data = {
            "name": video.title,
            "channelId": channel_id,
            # PeerTube does not allow empty description.
            "description": video.description or video.title,
            "privacy": 1,
            "tags[]": [k[:30] for k in video.keywords[:5]],
            "commentsEnabled": True,
            "category": 13
        }
        files = {
            "videofile": (
                video.attachment.get_filename(),
                open(video.attachment.get_file(), "rb"),
                video.attachment.mimetype,
            ),
            "previewfile": (
                video.get_thumbnail_filename(),
                open(video.get_thumbnail_file(), "rb"),
                "image/jpeg",
            ),
            "thumbnailfile": (
                video.get_thumbnail_filename(),
                open(video.get_thumbnail_file(), "rb"),
                "image/jpeg",
            ),
        }
        # req = requests.Request('POST', url, headers=headers, files=files, data=data)
        # prepared = req.prepare()
        # breakpoint()
        # # resp = req.send()
        resp = requests.post(url, headers=headers, files=files, data=data)
        if not resp.ok:
            print(resp.content)
            breakpoint()
            break
        video.peertube_uuid = resp.json()["video"]["uuid"]
        video.persist(force=True)
        count += 1
        if limit and count >= limit:
            break


if __name__ == "__main__":
    minicli.run()

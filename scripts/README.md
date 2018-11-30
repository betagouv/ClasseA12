# Migration scripts

The scripts in this folder are used to migrate the kinto data. They require python3 and kinto_http.

## Requirements

It's recommended to create a virtualenv:

```shell
$ python -m venv venv
```

Once that's done, you can install python packages inside it:

```shell
$ venv/bin/pip install kinto_http
```

## Running the scripts

The scripts are numbered, and usually start with a `videos` or `upcoming`
keyword, representing the collection they operate on.

To run a script:

```shell
$ venv/bin/python 001_videos_keywords_as_array.py --auth="<user>:<pass>"
```
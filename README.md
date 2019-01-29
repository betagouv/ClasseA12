# Classe à 12

Source code for the project [Classe à 12](https://beta.gouv.fr/startup/classes12.html).
This has been bootstraped with [elm-kitchen](https://allo-media.github.io/elm-kitchen/), see after the separator for more information.

To install and tinker:

```shell
$ git clone https://github.com/betagouv/ClasseA12
$ cd ClasseA12
$ npm install
$ npm start
```

Check out https://classea12.beta.gouv.fr/


## Kinto config

The backend is currently a [kinto](http://kinto.readthedocs.io/) instance.

The `kinto.ini` and `kinto.wsgi` files alongside this README file are good starting points to setup a Kinto instance on a wsgi web server, with the necessary configuration (detailed below).

It needs the [kinto accounts plugin](https://kinto.readthedocs.io/en/stable/configuration/settings.html#accounts).

It also needs the [keep_old_files
option](https://github.com/Kinto/kinto-attachment#the-keep_old_files-option):
when publishing a video, what we actually do is create a duplicate of the
video from the `upcoming` collection to the `videos` collection, then delete
the video from the `upcoming` collection. Without the `keep_old_files`
options the file would be deleted from the disk and not accessible anymore.

Make sure to also allow uploading video files by adding the following setting:

```kinto.attachment.extensions = default+video+mov```

Here's an example `kinto.ini` file:

```
# Kinto attachment
kinto.attachment.base_url = https://videos.classea12.beta.gouv.fr/
kinto.attachment.folder = {bucket_id}/{collection_id}
kinto.attachment.base_path = /path/to/folder/with/attachments
kinto.attachment.keep_old_files = true
kinto.attachment.extensions = default+video+mov
```

The `videos.classea12.beta.gouv.fr` domain name must point to a website
configured as a static files server which supports the `byte-range requests`
for the [videos to be playable on
Safari](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/CreatingVideoforSafarioniPhone/CreatingVideoforSafarioniPhone.html#//apple_ref/doc/uid/TP40006514-SW6).


### Users

There are two [users](https://kinto.readthedocs.io/en/stable/api/1.x/accounts.html):

- no user (anonymous): the basic "user" that has read access to the `/buckets/classea12/collections/videos/` collection
- `classea12admin:###`: the admin user that owns and has read and write access to the `/buckets/classea12/` bucket

### Kinto Resources

The resources metadata (data and permissions) are stored in `scripts/collections_metadata.py`.

#### Upcoming videos

`/buckets/classea12/collections/upcoming/`: `record:create` access to the `system.Authenticated` users. This is where videos proposed by teachers will be queued waiting to be accepted.

#### Published videos
`/buckets/classea12/collections/videos/`: read access to everyone (anonymous users), write access to the `classea12admin` user. This is where all the accepted videos are listed.

#### Video thumbnails

`/buckets/classea12/collections/thumbnails/`: `record:create` access to the `system.Authenticated` users. This is where thumbnails for videos proposed by teachers will be uploaded.

#### Email addresses for the newsletter

`/buckets/classea12/collections/contacts/`: `record:create` access to the `system.Authenticated` users (each form submission will use a unique ID to create the contact, preventing anyone to request the list of contacts). List of people registered to the newsletter.

#### User profiles

`/buckets/classea12/collections/profiles/`: `record:create` access to the `system.Authenticated` users, and read access to everyone (anonymous users). A profile will then be added to the user account record. The profile will hold any public information about a user (their name, bio...).

#### Comments

`/buckets/classea12/collections/comments/`: `record:create` access to the `system.Authenticated` users, and read access to everyone (anonymous users). A comment will link a profile ID to a video ID.

# Deployment

- Kinto is hosted on an [alwaysdata](https://www.alwaysdata.com/) [account](https://kinto.classea12.beta.gouv.fr/v1)
- on the same account, the frontend static files are pushed to a git repository using [gh-pages](https://www.npmjs.com/package/gh-pages) with `npm run deploy`

For this second part to work, here's the recipe:

## Bare git clone with a post-receive hook on the server

```shell
$ cd git
$ git clone --bare https://github.com/betagouv/ClasseA12.git
$ vim ClasseA12/hooks/post-receive
```

Content of the `post-receive` hook:

```shell
#!/bin/sh
while read oldrev newrev ref
do
    if [ "$ref" = "refs/heads/gh-pages" ];
    then
        echo "Deploying 'gh-pages' branch"
        git --work-tree=/path/to/www/ClasseA12 --git-dir=/path/to/git/ClasseA12.git checkout --force gh-pages
        exit 0
    fi
done
```

## Adding a remote to the alwaysdata account on the dev machine

```shell
$ git remote add deploy-prod classea12@ssh-classea12.alwaysdata.net:~/git/ClasseA12.git
```

Then, to deploy, run

```shell
$ npm run deploy-prod
```

Additionnally you may add a different `deploy` remote, and use the `npm run deploy` command, for example to deploy to a different staging server.

## Web server configuration

As a SPA, every URL needs to be managed by the index.html file (which has the
javascript generated from the elm code).
This can be done using a nodejs server like [expressjs](https://expressjs.com/), or by using some apache configuration like the following in a virtual host:

```
DocumentRoot "/path/to/www/ClasseA12/"

<Directory /path/to/www/ClasseA12>
    Order allow,deny
    allow from all
    Options -Indexes -Includes -ExecCGI
    Options FollowSymlinks

    # This will make sure all the URLs that don't point to a file on disc will be processed by the
    # main entry point in index.html
    RewriteEngine On
    RewriteBase /
    RewriteRule ^index\.html$ - [L]
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /index.html [L]
</Directory>
```

# Dev

During development, the kinto server used is https://kinto-dev.classea12.beta.gouv.fr/v1. It's automatically changed to https://kinto.classea12.beta.gouv.fr/v1 when using the `npm run deploy-prod` command.

----

# elm-kitchen

This is a modest attempt at providing a simplistic yet opinionated Elm [SPA](https://en.wikipedia.org/wiki/Single-page_application) application skeleton based on rtfeldman's [Elm Example SPA](https://github.com/rtfeldman/elm-spa-example/), for [Allo-Media](http://tech.allo-media.net/)'s own needs.

[Check for yourself](https://allo-media.github.io/elm-kitchen/)

## Features

- Elm 0.19 ready
- Multiple pages navigation & routing
- Live development server with hot reloading
- [elm-test](https://github.com/elm-community/elm-test) support
- [elm-css](http://package.elm-lang.org/packages/rtfeldman/elm-css/latest) support

## Code organization

The application stores Elm source code in the `src` directory:

```
$ tree --dirsfirst skeleton/src
src
├── Data
│   └── Session.elm
├── Page
│   ├── Home.elm
│   └── SecondPage.elm
├── Request
│   └── Github.elm
├── Views
│   ├── Page.elm
│   └── Theme.elm
├── Main.elm
└── Route.elm
```

Richard Feldman explains this organization in a [dedicated blog post](https://dev.to/rtfeldman/tour-of-an-open-source-elm-spa).

## Installation

```
$ npm install -g elm-kitchen
$ elm-kitchen my-app
$ cd my-app
$ npm install
```

## Usage

To start the development server:

```
$ npm start
```

This will serve and recompile Elm code when source files change. Served application is available at [localhost:3000](http://localhost:3000/).

## Tests

```
$ npm test
```

Tests are located in the `tests` folder and are powered by [elm-test](https://github.com/elm-community/elm-test).

## Build

```
$ npm run build
```

The resulting build is available in the `build` folder.

## Deploy

A convenient `deploy` command is provided to publish code on [Github Pages](https://pages.github.com/).

```
$ npm run deploy
```

## License

[MIT](https://opensource.org/licenses/MIT)

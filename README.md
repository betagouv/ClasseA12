# Classe à 12

Source code for the project [Classe à 12](https://beta.gouv.fr/startup/classes12.html).
This has been bootstraped with [elm-kitchen](https://allo-media.github.io/elm-kitchen/), see after the separator for more information.

To install and tinker:

```shell
$ git clone https://github.com/magopian/ClasseA12
$ cd ClasseA12
$ npm install
$ npm start
```

Check out https://classea12.beta.gouv.fr/


## Kinto config

The backend is currently a [kinto](http://kinto.readthedocs.io/) instance.

It needs the [kinto accounts plugin](https://kinto.readthedocs.io/en/stable/configuration/settings.html#accounts).

### Users

There are two [users](https://kinto.readthedocs.io/en/stable/api/1.x/accounts.html):

- `classea12:notasecret`: the basic user that has read access to the `/buckets/classea12/collections/videos/` collection
- `classea12admin:###`: the admin user that owns and has read and write access to the `/buckets/classea12/` bucket

### Resources

- `/buckets/classea12/collections/upcoming/`: `record:create` access to the `classea12` user. This is where videos proposed by teachers will be queued waiting to be accepted.
- `/buckets/classea12/collections/videos/`: read access to the `classea12` user, write access to the `classea12admin` user. This is where all the accepted videos are listed.
- `/buckets/classea12/collections/contacts/`: `record:create` access to the `system.Authenticated` users (each form submission will use a unique ID to create the contact, preventing anyone to request the list of contacts). List of people registered to the newsletter.

# Deployment

This will change in the future, but for now:
- Kinto is hosted on an [alwaysdata](https://www.alwaysdata.com/) [account](https://kinto.agopian.info/v1)
- on the same account, the frontend static files are pushed to a git repository using [gh-pages](https://www.npmjs.com/package/gh-pages) with `npm run deploy`

For this second part to work, here's the recipe:

## Bare git clone with a post-receive hook on the server

```shell
$ cd git
$ git clone --bare https://github.com/magopian/ClasseA12.git
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
        git --work-tree=/home/agopian/www/ClasseA12 --git-dir=/home/agopian/git/ClasseA12.git checkout --force gh-pages
        exit 0
    fi
done
```

## Adding a remote to the alwaysdata account on the dev machine

```shell
$ git remote add deploy agopian@ssh-agopian.alwaysdata.net:~/git/ClasseA12.git
```

Then, to deploy, run

```shell
$ npm run deploy
```

## Web server configuration

As a SPA, every URL needs to be managed by the index.html file (which has the
javascript generated from the elm code).
This can be done using a nodejs server like [expressjs](https://expressjs.com/), or by using some apache configuration like the following in a virtual host:

```
# This will make sure all the URLs that don't point to a file on disc will be processed by the
# main entry point in index.html
FallbackResource /

DocumentRoot "/path/to/ClasseA12/"

<Directory />
    Order Deny,Allow
    Deny from all
    Options -Indexes -Includes -ExecCGI -FollowSymlinks
</Directory>

<Directory /path/to/ClasseA12>
    Order allow,deny
    allow from all
    Options -Indexes -Includes -ExecCGI -FollowSymlinks
</Directory>
```

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

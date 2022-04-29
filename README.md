# Devoirs Faits

Source code for the project [Devoirs Faits](https://beta.gouv.fr/startups/classe-a-12.html).
This has been bootstraped with [elm-kitchen](https://allo-media.github.io/elm-kitchen/), see after the separator for more information.
The project is bundled using [create-elm-app](https://github.com/halfzebra/create-elm-app).

To install and tinker (we use yarn because depency resolution seems to work better in our case):

```shell
$ git clone https://github.com/betagouv/ClasseA12
$ cd ClasseA12
$ yarn install
$ yarn start
```

Check out https://classe-a-12.beta.gouv.fr


# Deployment

The frontend static files are pushed to a git repository using [gh-pages](https://www.npmjs.com/package/gh-pages) with `yarn run deploy`

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
$ yarn run deploy-prod
```

Additionnally you may add a different `deploy` remote, and use the `yarn run deploy` command, for example to deploy to a different staging server.

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
$ yarn install -g elm-kitchen
$ elm-kitchen my-app
$ cd my-app
$ yarn install
```

## Usage

To start the development server:

```
$ yarn start
```

This will serve and recompile Elm code when source files change. Served application is available at [localhost:3000](http://localhost:3000/).

## Tests

```
$ yarn test
```

Tests are located in the `tests` folder and are powered by [elm-test](https://github.com/elm-community/elm-test).

## Build

```
$ yarn run build
```

The resulting build is available in the `build` folder.

## Deploy

A convenient `deploy` command is provided to publish code on [Github Pages](https://pages.github.com/).

```
$ yarn run deploy
```

## License

[MIT](https://opensource.org/licenses/MIT)

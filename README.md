# Classe à 12

Source code for the project [Classe à 12](https://beta.gouv.fr/recrutement/2018/08/29/classes12-dev.html).
This has been bootstraped with [elm-kitchen](https://allo-media.github.io/elm-kitchen/), see after the separator for more information.

To install and tinker:

```shell
$ git clone https://github.com/magopian/ClasseA12
$ cd ClasseA12
$ npm install
$ npm start
```

Check the [demo](https://magopian.github.io/ClasseA12/)


## Kinto config

The backend is currently a [kinto](http://kinto.readthedocs.io/) instance.

It needs the [kinto accounts plugin](https://kinto.readthedocs.io/en/stable/configuration/settings.html#accounts).

### Users

There are two [users](https://kinto.readthedocs.io/en/stable/api/1.x/accounts.html):

- `classea12:notasecret`: the basic user that has read access to the `/buckets/classea12/collections/videos/` collection
- `classea12admin:###`: the admin user that owns and has read and write access to the `/buckets/classea12/` bucket

### Resources

- `/buckets/classea12/collections/upcoming/`: write access to the `classea12` user. This is where videos proposed by teachers will be queued waiting to be accepted.
- `/buckets/classea12/collections/videos/`: read access to the `classea12` user. This is where all the accepted videos are listed.

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

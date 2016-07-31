# Dundler

Dundler is an extremely bad prototype of an idea I had while talking to a friend
of mine about bundle install and docker.

Don't use it.

## How to use it

Because this is an extremely bad prototype, it currently makes a lot of
assumptions about the setup of your project. These are they:

1. You have a `Gemfile` and `Gemfile.lock` in your project
2. Your `dockerfile` adds those two files **before** doing anything else, as to
   cache dependencies.
3. You are using git and your `Dockerfile` is checked in on master.
4. You have `.bundle` and `vendor/cache` dockerignored.

Dundler generates a file called `Dockerfile.dundler` which contains `RUN gem
install` commands for each gem required by your `Gemfile`. It parses
`Gemfile.lock` and uses some heuristics to determine which order these should go
in. The idea here is that adding new gems should never churn an old layer,
meaning that your bundle installs run a fair bit faster in your containers.

The `dundler.rb` file in this repo can be installed in a myriad of ways, but I
suggest you just copy it in to your project.

Let's imagine you've got a rails project that you build with the following
`Dockerfile`:

```
FROM ruby:2.3

RUN mkdir /app
WORKDIR /app

COPY Gemfile ./
COPY Gemfile.lock ./
RUN bundle install

COPY . ./
```

And a `docker-compose.yml`:

```
version: '2'
services:
  web:
    build: .
    ports:
     - "3000:3000"
    volumes:
     - .:/app
    command:
     - bundle exec rails s
```

To use dundler, just run `ruby dundler.rb` and the `Dockerfile.dundler` will get
emitted. Then, add it to your `docker-compose.yml`

```
version: '2'
services:
  web:
    build:
      context: .
      dockerfile: Dockerfile.dundler
    ports:
     - "3000:3000"
    volumes:
     - .:/app
    command:
     - bundle exec rails s
```

Now, run `docker-compose build`. It might take a little longer the first time.
However, every time you now add a gem to your `Gemfile` and run `bundle install`
locally, you can then run `ruby dundler.rb` to regenerate the
Dockerfile.dundler, which should add a new series of `RUN gem install` lines,
caching the earlier dependencies, and significantly speeding up your build.

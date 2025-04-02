# Contributing to Sender25

This doc explains how to go about running Sender25 in development to allow you to make contributions to the project.

## Dependencies

You will need a MySQL database server to get started. Sender25 needs to be able to make databases within that server whenever new mail servers are created so the permissions that you use should be suitable for that.

You'll also need Ruby. Sender25 currently uses Ruby 3.2.2. Install that using whichever version manager takes your fancy - rbenv, asdf, rvm etc.

## Clone

You'll need to clone the repository

```
git clone git@github.com:sender25server/sender25
```

Once cloned, you can install the Ruby dependencies using bundler.

```
bundle install
```

## Configuration

Configuration is handled using a config file. This lives in `config/sender25/sender25.yml`. An example configuration file is provided in `config/examples/development.yml`. This example is for development use only and not an example for production use.

You'll also need a key for signing. You can generate one of these like this:

```
openssl genrsa -out config/sender25/signing.key 2048
```

If you're running the tests (and you probably should be), you'll find an example file for test configuration in `config/examples/test.yml`. This should be placed in `config/sender25/sender25.test.yml` with the appropriate values.

If you prefer, you can configure Sender25 using environment variables. These should be placed in `.env` or `.env.test` as apprpriate.

## Running

The neatest way to run sender25 is to ensure that `./bin` is your `$PATH` and then use one of the following commands.

* `bin/dev` - will run all components of the application using Foreman
* `bin/sender25` - will run the Sender25 binary providing access to running individual components or other tools.

## Database initialization

Use the commands below to initialize your database and make your first user.

```
sender25 initialize
sender25 make-user
```

![Deploy](https://github.com/DFE-Digital/govuk-rails-boilerplate/workflows/Deploy/badge.svg)

# npq-registration (National Professional Qualification)

## Prerequisites

- Ruby 2.7.2
- PostgreSQL
- NodeJS 14.16.1
- Yarn 1.12.x

## Setting up the app in development

1. Run `bundle install` to install the gem dependencies
2. Run `yarn` to install node dependencies
3. Run `bin/rails db:setup` to set up the database development and test schemas, and seed with test data
4. Run `bundle exec rails server` to launch the app on http://localhost:3000
5. Run `./bin/webpack-dev-server` in a separate shell for faster compilation of assets

## Running specs, linter(without auto correct) and annotate models and serializers
```
bundle exec rake
```

## Running specs
```
bundle exec rspec
```

## Linting

It's best to lint just your app directories and not those belonging to the framework, e.g.

```bash
bundle exec rubocop app config db lib spec Gemfile --format clang -a

or

bundle exec scss-lint app/webpacker/styles
```

## Docker

### Prerequisites
- Docker >= 19.03.12

### Build
```
make build-local-image
```

### Single docker image
The docker image doesn't contain a default command. Any command can be appended:
```
% docker run -p 3001:3000 dfedigital/govuk-rails-boilerplate:latest rails -vT
rails about                              # List versions of all Rails frameworks and the environment
rails action_mailbox:ingress:exim        # Relay an inbound email from Exim to Action Mailbox (URL and INGRESS_PASSWORD required)
...
```

### Run in production mode
Docker compose provides a default empty database to run rails in production mode.

```
docker-compose up
```

Open: http://localhost:3000

## Deploying on GOV.UK PaaS

- Deployments are performed through GitHub actions

## ssh-ing into an environment

### Prerequisites

- Cloud Foundry v7 client
- GOV.UK PaaS account

### Getting a rails console

```sh
cf ssh npq-registration-dev
export PATH="/usr/local/bundle/bin:/usr/local/bundle/gems/bin:/usr/local/bin:$PATH"
cd /app
bundle exec rails c
```

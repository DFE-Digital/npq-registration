![Tests](https://github.com/DFE-Digital/npq-registration/actions/workflows/test.yml/badge.svg)
![Deployment](https://github.com/DFE-Digital/npq-registration/actions/workflows/deploy_to_dev.yml/badge.svg)

# npq-registration (National Professional Qualification)

## Prerequisites

- Ruby 3.1.2
- PostgreSQL
- NodeJS 16.16.0
- Yarn 1.12.x

## Setting up the app in development

1. Run `bundle install` to install the gem dependencies
2. Run `yarn` to install node dependencies
3. Run `bin/rails db:setup` to set up the database development and test schemas, and seed with test data
4. Run `bundle exec rails server` to launch the app on http://localhost:3000
5. Run `./bin/webpack-dev-server` in a separate shell for faster compilation of assets

## Importing schools

- fire up a rails console and run the following
- `Services::ImportGiasSchools.new.call`

## Importing premium pupils data

- fire up a rails console and run the following
- `Services::SetHighPupilPremiums.new(path_to_csv: Rails.root.join("config/data/high_pupil_premiums_2021_2022.csv")).call`

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

## Runbook

### Manual validation lifecycle

This is for users that have entered their details but we could not automatically validate with the TRA database via API call. Instead we export these users for a human to validate then re-import the data.

- Export records as CSV for manual validation
```ruby
Services::Exporters::ManualValidation.new.call
```
- After manual validation is complete we need to import the data back into NPQ
```ruby
Services::Importers::ManualValidation.new(path_to_csv: "/PATH/TO.CSV").call
```
- The data will not be synced with ECF so must also be updated there too with the same CSV
- So inside a rails console in ECF
```ruby
Importers::NPQManualValidation.new(path_to_csv: "/PATH/TO.CSV").call
```
- Import is now complete and we need to generate the next batch of manual validation records from NPQ
```ruby
Services::Exporters::ManualValidation.new.call
```

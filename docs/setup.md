[< Back to Navigation](../README.md)

# Setting up the app

1. [Local development](#local-development)
2. [Codespaces](#codespaces)
3. [Docker](#docker)

## Local development

1. Install the prerequisites:
- Ruby 3.3.3
- PostgreSQL
- NodeJS 16.19.1
- Yarn 1.12.x
1. Run `bundle install` to install the gem dependencies
1. Run `yarn` to install node dependencies
1. Run `bin/rails db:setup` to set up the database development and test schemas, and seed with test data
1. Copy `.env.example` to `.env` and fill in the values (Get an identity secret can be acquired from members of the TRA team)
1. Run `bundle exec rails server` to launch the app on http://localhost:3000
1. Run `./bin/webpack-dev-server` in a separate shell for faster compilation of assets

## Codespaces

1. Click the green 'Code' button on the repository home page and click 'Create a Codespace'
2. Run `bundle exec rails server` in the terminal window at the bottom of VS Code

If you're unfamiliar with what Codespaces are or how they work [read the official guiude](https://docs.github.com/en/codespaces/overview). If you
don't have access to them you can request it in `#digital-tools-support` on DfE Slack.

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

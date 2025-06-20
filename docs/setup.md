[< Back to Navigation](../README.md)

# Setting up the app

1. [Local development](#local-development)
2. [Codespaces](#codespaces)
3. [Docker](#docker)
4. [Docker Compose](#docker-compose)

## Local development

1. Install the prerequisites:
- Ruby 3.3.8
- PostgreSQL
- NodeJS 20.15.1
- Yarn 1.22.x
- Graphviz
1. Run `bundle install` to install the gem dependencies
1. Run `yarn` to install node dependencies
1. Run `bin/rails db:setup` to set up the database development and test schemas, and seed with test data
1. Copy `.env.example` to `.env` and fill in the values (Get an identity secret can be acquired from members of the TRA team)
1. Run `./bin/dev` to launch the app on http://localhost:3000 and auto-compile assets

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

## Docker Compose

Starts the stack (database and application) for development. You only need Docker on your machine.

```
docker-compose up -d
```

Open http://localhost:3000 to browse the app. Edit code as normal (the project directory is mounted as a volume.)

Prefix other commands with `docker compose run web`, e.g.:
- `docker compose run web bundle exec rails c`
- `docker compose run web bundle exec rails db:migrate`
- `docker compose run web bundle exec rake`
- `docker compose run web bundle add foobar`

n.b. to run parallel tests, you need to explicitly set RAILS_ENV e.g.: `docker compose run -e RAILS_ENV=test web bundle exec rake parallel:spec`

If you need to rebuild the image (e.g. `Gemfile.lock` changed), add `--build`: `docker compose up -d --build`

### ops service

The `ops` service (`docker compose run ops`) starts a bash shell with `make`, `az` and `kubectl` ready to use.

You can also use this service to run konduit:

1. After installing with `make install-konduit` as normal, edit konduit.sh:
    1. In `open_tunnels()` change `kubectl port-forward [...]` to `kubectl port-forward --address 0.0.0.0 [...]`
    2. In `set_db_psql()`, edit `DB_URL=` replacing `127.0.0.1:${LOCAL_PORT}` with `konduit:${LOCAL_PORT}`

2. To create the tunnel, `docker compose run --rm --name konduit ops make <target environment> konduit`

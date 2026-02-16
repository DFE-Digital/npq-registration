[< Back to Navigation](../README.md)

# Setting up the app for development

1. [Local development](#local-development)
2. [Codespaces](#codespaces)
3. [Docker Compose](#docker-compose)

## Local development

1. Install the prerequisites (see `.tool-versions` for versions):
   - Ruby
   - PostgreSQL 14 or higher (v14 is [deprecated on homebrew](https://formulae.brew.sh/formula/postgresql@14), so v15 or later is recommended)
   - NodeJS
   - Yarn
   - Graphviz
1. Run `bundle install` to install the gem dependencies
1. Run `yarn` to install node dependencies
1. Run `bin/rails db:setup` to set up the database development and test schemas, and seed with test data
1. Copy `.env.example` to `.env` and fill in the values (ask a team member for `TRA_OIDC_*` values)
1. Run `./bin/dev` to launch the app on http://localhost:3000 and auto-compile assets

## Codespaces

1. Click the green 'Code' button on the repository home page and click 'Create a Codespace'
1. The server should automatically run - check the 'Ports' tab at the bottom of the window, the application runs under port 3000.

If you're unfamiliar with what Codespaces are or how they work [read the official guiude](https://docs.github.com/en/codespaces/overview). If you
don't have access to them you can request it in `#digital-tools-support` on DfE Slack.

## Docker Compose

You only need Docker on your machine. Start the stack (database and application) for development:

```bash
docker compose up -d
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

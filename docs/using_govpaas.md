[< Back to Navigation](../README.md)

# Using GovPaaS

There situations in the dev environment where it would be useful to see server logs, have database access, or rails console access.
This should not be used in other environments.

1. [Setup](#setup)
1. [Changing Space](#changing-space)
1. [View logs](#view-logs)
1. [Database access](#database-access)
1. [Rails console](#rails-console)
1. [Other SSH access (SCP)](#other-ssh-access-scp)

## Setup

The following assumed you have the cloudfoundry CLI set up on your machine, and have logged in.
When you log in, you should select the dev space. Instructions can be found [here](https://docs.cloud.service.gov.uk/get_started.html#set-up-the-cloud-foundry-command-line)

## Changing Space

If you need to change space, for example to move between the dev space and the staging space you can use the following commands.

To view available spaces:

```cf spaces```

To change to a different space:

```cf target -s <space_name>```

## View logs

To view logs, you will first need to know the service name. `cf a` will list services, but the service name will probably be `ecf-dev`.

To view recent logs:

```cf logs --recent <app_name>```

To tail logs (view them as they are generated)

```cf logs <app_name>```

## Database Access

You will need to have the `psql` command on your path for this to work.
For a Debian/Ubuntu based system, this can be achieved with `sudo apt-get install postgresql-client-12`
On mac, installing through homebrew with `brew install postgres` is probably easiest. Alternative instructions [here](https://www.postgresql.org/download/macosx/).

The first time you try this, you will need to install the conduit plugin:

`cf install-plugin conduit`

You can list the services with `cf s`, but the service name will generally be `ecf-postgres-dev`. For interactive access, use:

`cf conduit ecf-postgres-dev -- psql`

## Rails console
First, ssh into the host instance

`cf ssh <app_name>`

Then,

`cd /app`

and finally

`/usr/local/bin/bundle exec rails console`

## Other SSH access (SCP)
Find the instance guid

`GUID=$(cf app ecf-production-worker --guid)`

Generate a single use login code

`cf ssh-code` | [xsel|pbcoby]

Perform the SCP command

`scp -P 2222 -o StrictHostKeyChecking=no -oHostKeyAlgorithms=+ssh-rsa -o User=cf:${GUID}/0 [from] [to]`

using the password from `cf ss-code`

e.g.

`scp -P 2222 -o StrictHostKeyChecking=no -oHostKeyAlgorithms=+ssh-rsa -o User=cf:${GUID}/0 ssh.london.cloud.service.gov.uk:/app/*.csv .`

In cases where the is more than one instance, change the `/0` to match the desired instance number

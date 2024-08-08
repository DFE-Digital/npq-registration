[< Back to Navigation](../README.md)

# Merging and Deployment Process

1. [Continuous Integration](#continuous-integration)
1. [Requirements to merge to main](#requirements-to-merge-to-main)
1. [Environment Variables](#environment-variables)

## Continuous Integration

Deployment occurs automatically upon merging into the main branch. This deployment will go to the sandbox, dev, and production environments.

As deployment occurs, the commit hash that is deployed to production will be tagged as a production release with a timestamp of when it went live, this tag will follow the format: `prod-release-<timestamp>-<commit-hash>`. Looking like this: `prod-release-2022-08-31-14-09-1212c83`.

Deployment is handled by Github Actions, the workflow that handles this can be found in multiple workflows, one for each environment:
- [Deploy to Dev](../.github/workflows/deploy_to_dev.yml)
- [Deploy to Sandbox](../.github/workflows/deploy_to_sandbox.yml)
- [Deploy to Production](../.github/workflows/deploy_to_production.yml)
- [Deploy to Review App](../.github/workflows/deploy_to_review_app.yml)

See the [environments](../docs/environments.md) document for more information on these environments.

## Requirements to merge to main

PRs aimed at the main branch have two mandatory requirements:
1. At least one approving code review from someone in the CODEOWNERS file in the repo, this can be seen [here](.github/CODEOWNERS).
2. Passing tests and code linters that will automatically run when your code is pushed

### Optional requirements

Approval from the product owner, testing can be performed using the review app that is deployed automatically for all PRs.

## Environment Variables

Environment variables are set within the Github repository, these are then passed to CloudFoundry when the application is deployed.

Environment variables can be managed at (https://github.com/DFE-Digital/npq-registration/settings/secrets/actions).

These will then be available within the Github Action workflows as `secrets.<secret_name>`. This can be seen in each of the deployment scripts linked above.

Environment variables intended for setting on the CloudFoundry application itself are passed into the `cf push` command as `--var <key>=<value>`.
They are then set as environment variables on the application's environment manifest:
- [Dev environment manifest](../config/manifests/dev-manifest.yml)
- [Sandbox environment manifest](../config/manifests/sandbox-manifest.yml)
- [Production environment manifest](../config/manifests/prod-manifest.yml)
- [Review App environment manifest](../config/manifests/review-app-manifest.yml)

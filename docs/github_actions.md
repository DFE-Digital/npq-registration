[< Back to Navigation](../README.md)

# Github Actions

## Overview

Github Actions is used to run automated tests and linting on pull requests. 

It is also used to deploy the application to the dev, sandbox, review app and production environments.

Automated tasks also run via Github Actions. Typically tasks run on a server are set up to trigger a rake task, you can see this pattern in the update schools task below.

1. [PR Tests and Linting](#pr-tests-and-linting-testyml)
1. [Schedule Sweep Stale Sessions](#schedule-sweep-stale-sessions-schedule_sweep_stale_sessionsyml)
1. [Update Course Definitions](#update-course-definitions-update_course_definitionsyml)
1. [Update Schools](#updating-schools)
1. [Deploy scripts](#deploy-scripts)
1. [BigQuery Reports](#bigquery-reports)
1. [Get an Identity Data Sync](#get-an-identity-data-sync-allunsynceduser)

You can see all the workflows in the [workflows directory](../.github/workflows).

## Workflows

### PR Tests and Linting ([test.yml](../.github/workflows/test.yml))

This workflow is triggered when a pull request is opened or updated. It runs the tests, brakeman and linters. Must pass before a merge can be completed.

### Schedule Sweep Stale Sessions ([schedule_sweep_stale_sessions.yml](../.github/workflows/schedule_sweep_stale_sessions.yml))

Runs once a day to delete stale sessions from the database.

### Update Course Definitions ([update_course_definitions.yml](../.github/workflows/update_course_definitions.yml))

Runs on demand to update course definitions in the database. Syncing them to match `Courses::DEFINITIONS`.

### Update Application Statuses ([update_application_statuses.yml](../.github/workflows/update_application_statuses.yml))

Runs once a day to update applications lead_provider_approval_status and participant_outcome_state retrieved from the ecf.

### Updating Schools

See [Importing schools](importing_data.md#importing-schools) for more information.

#### Update Schools ([update_schools.yml](../.github/workflows/update_schools.yml))

Runs once a day to update schools in the database.

Pulls data down from the Get Information About Schools (GIAS) service and updates the database with the latest information. Only updates schools that have changed since the last update.

#### Update All Schools ([update_all_schools.yml](../.github/workflows/update_all_schools.yml))

Runs on demand to update all schools in the database.

Pulls data down from the Get Information About Schools (GIAS) service and updates the database with the latest information. Ignores timestamped changes and updates all schools.

### Deploy scripts

#### Deploy to Dev ([deploy_to_dev.yml](../.github/workflows/deploy_to_dev.yml))

This workflow is triggered when a pull request is merged into the main branch. It deploys the application to the dev environment.

#### Deploy to Sandbox ([deploy_to_sandbox.yml](../.github/workflows/deploy_to_sandbox.yml))

This workflow is triggered when a pull request is merged into the main branch. It deploys the application to the sandbox environment.

#### Deploy to Production ([deploy_to_production.yml](../.github/workflows/deploy_to_production.yml))

This workflow is triggered when a pull request is merged into the main branch. It deploys the application to the production environment.

#### Deploy to Review App ([deploy_to_review_app.yml](../.github/workflows/deploy_to_review_app.yml))

This workflow is triggered when a pull request is opened or updated. It deploys the application to a review app environment.

#### Destroy Review App ([destroy_review_app.yml](../.github/workflows/destroy_review_app.yml))

This workflow is triggered when a pull request is closed or merged. It destroys the review app attached to the PR.

### Get an Identity Data Sync (all/unsynced/user)

- [get_an_identity_data_sync_all.yml](../.github/workflows/get_an_identity_data_sync_all.yml),
- [get_an_identity_data_sync_unsynced.yml](../.github/workflows/get_an_identity_data_sync_unsynced.yml)
- [get_an_identity_data_sync_user.yml](../.github/workflows/get_an_identity_data_sync_user.yml)

Runs on demand to sync user information from the Get an Identity service to the NPQ app and then feed it on to ECF. Used for refreshing stale data as needed, this is not a scheduled task and is typically not needed.

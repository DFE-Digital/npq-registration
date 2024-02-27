[< Back to Navigation](../README.md)

# Migration Environment

## Overview

The migration environment is a temporary environment we have put in place to facilitate the separation of NPQ-specific behavior from the [ECF application](https://github.com/DFE-Digital/early-careers-framework). We will be using this environment for testing the code added/migrated from ECF and also for running test data migrations to bring across the necessary data from the ECF database.

## Deployment

- A merge to `main` will trigger a deployment to the migration environment.
- The instance is hosted at [https://npq-registration-migration-web.teacherservices.cloud/](https://npq-registration-migration-web.teacherservices.cloud/).

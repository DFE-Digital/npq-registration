[< Back to Navigation](../README.md)

# Environments

There are three permanent environments for NPQ and a fourth set of transient environments, the three permanent are sandbox, dev (Staging in Azure) , and production. The fourth transient set are review apps

- [Environments](#environments)
  - [Review Apps](#review-apps)
  - [Staging](#staging)
  - [Sandbox](#sandbox)
  - [Migration](#migration)
  - [Separation](#separation)
  - [Production](#production)

## Review Apps

- Deployed on raising a PR/merging to a branch (branching off `main` only). Destroyed when the PR is merged/closed.
- Part of the `test` Azure space.
- Used internally by team members to review changes prior to deploying.
- https://npq-registration-review-<PR-NUMBER>-web.test.teacherservices.cloud

## Staging

- Deployed on merging to `main`.
- Part of the `test` Azure space.
- Used internally by team members as a production-like environment.
- https://npq-registration-staging-web.test.teacherservices.cloud
- [View deployed commit](https://npq-registration-staging-web.test.teacherservices.cloud/healthcheck.json)

## Sandbox

- Deployed on merging to `main`.
- Part of the `production` Azure space.
- Enables lead providers and other external users to explore the service without putting data into our production system.
- Submitted applications are pushed to the sandbox ECF environment.
- https://npq-registration-sandbox-web.teacherservices.cloud
- [View deployed commit](https://npq-registration-sandbox-web.teacherservices.cloud/healthcheck.json)

## Migration

- Deployed on merging to `main`.
- Part of the `production` Azure space.
- Temporary environment for NPQ separation work.
- Used internally by team members as a production-like environment with NPQ separation features enabled.
- Migration feature (for NPQ separation) will pull from the migration ECF environment.
- https://npq-registration-migration-web.teacherservices.cloud
- [View deployed commit](https://npq-registration-migration-web.teacherservices.cloud/healthcheck.json)

## Separation

- Deployed on merging to `main`.
- Part of the `production` Azure space.
- Temporary environment for NPQ separation work.
- Enables lead providers and other external users to explore the NPQ separation endpoints.
- Migration feature (for NPQ separation) is currently disabled as we have no corresponding environment in ECF to pull from.
- https://npq-registration-separation-web.teacherservices.cloud
- [View deployed commit](https://npq-registration-separation-web.teacherservices.cloud/healthcheck.json)

## Production

- Deployed on merging to `main`.
- Part of the `production` Azure space.
- The production environment is the live system, users that are applying for NPQs fill in the forms in this system. Once submitted applications are pushed to the production ECF environment and then out to lead providers.
- https://register-national-professional-qualifications.education.gov.uk
- [View deployed commit](https://register-national-professional-qualifications.education.gov.uk/healthcheck.json)

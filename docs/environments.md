[< Back to Navigation](../README.md)

# Environments

There are three permanent environments for NPQ and a fourth set of transient environments, the three permanent are sandbox, dev (Staging in Azure) , and production. The fourth transient set are review apps

1. [Sandbox](#sandbox)
1. [Dev (Staging in Azure)](#dev-staging-in-aAure)
1. [Production](#production)
1. [Review Apps](#review-apps)

## Sandbox

The sandbox environment is automatically deployed to in the same way as production, any time anything is merged it will be deployed to the sandbox environment.
This environment is here for lead providers and other external users to be able to explore the service without putting data into real production systems. Once submitted applications are pushed to the sandbox ECF environment.

You can view the sandbox environment at https://npq-registration-sandbox.london.cloudapps.digital
You can view which commit is deployed to the sandbox environment by going to https://npq-registration-sandbox.london.cloudapps.digital/healthcheck.json

## Dev (Staging in Azure)

The dev environment is also automatically deployed in the same way as production, any time anything is merged it will be deployed to the Dev environment.
This environment is here for internal members of the team to be able to explore the environment as it is in production without putting data into real production systems.

You can view the dev environment at https://npq-registration-dev.london.cloudapps.digital
You can view which commit is deployed to the dev environment by going to https://npq-registration-dev.london.cloudapps.digital/healthcheck.json

The URLs for this environment might change after the migration to Azure

## Production

The production environment is the live system, users that are applying for NPQs fill in the forms in this system. Once submitted applications are pushed to the production ECF environment and then out to lead providers.

You can view the production environment at https://register-national-professional-qualifications.education.gov.uk
You can view which commit is live on production by going to https://register-national-professional-qualifications.education.gov.uk/healthcheck.json

## Review Apps

Review apps are short lived environments that are spun up any time a PR is filed on Github.
These environments are for us to test features before merging them, so that we can review and approve features on a real environment before they are deployed.
Please keep in mind that at least for the time being all review apps share a database.

The URL for these differ but follow the format: https://npq-registration-review-app-<PR_NUMBER>.london.cloudapps.digital/

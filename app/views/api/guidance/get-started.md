# Get started

## Connect to the API

Connect to the API by integrating local provider CRM systems with it. A unique authentication token is needed to
connect to the API. Each token is associated with a single provider and will give providers access to appropriate CPD
participant data. Authentication tokens do not expire.

## Production environment

The production environment is the live environment which processes real data.

## Rate limits

Providers are limited to 1000 requests per 5 minutes when using the API in the production environment. If the limit is
exceeded, providers will see `429` HTTP status codes.

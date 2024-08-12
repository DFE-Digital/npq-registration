# Get started

## Connect to the API

Providers integrate their local CRM systems by connecting to this API's test environments.

We'll add information about connecting to the production environments when they go live in November 2024.

## Request an authentication (bearer) token

Providers need to use a unique authentication (bearer) token to connect to the API.

[Email us](mailto:continuing-professional-development@digital.education.gov.uk) if you do not already have this token. We'll send it via secure email.

The tokens do not expire.

<div class="govuk-warning-text">
  <span class="govuk-warning-text__icon" aria-hidden="true">!</span>
  <strong class="govuk-warning-text__text">
    <span class="govuk-visually-hidden">Warning</span>
    Don't share tokens in publicly accessible documents or repositories.
  </strong>
</div>

### How to use an authentication token

Include an authentication token in all requests to the API by adding an `Authorization` request header (not as part of the URL) in the following format:

```
Authorization: Bearer {token}
```

Unauthenticated requests will receive an `UnauthorizedResponse` with a `401` error code.

## Test environments

The test environments feature all the NPQ API request endpoints and have been populated with seed data which cover scenarios where users have:

* one application
* multiple applications
* accepted applications
* rejected applications

The base URL for the API's test environments is:

* [https://npq-registration-separation-web.teacherservices.cloud](https://npq-registration-separation-web.teacherservices.cloud)

Providers can add the required API version and endpoint depending on what they want to test. For example, they’d add `/api/v3/npq-applications` to the test environment URL if they want to retrieve multiple applications.

Providers can also create ‘dummy’ applications in the separation environment. This enables them to:

* generate individualised seed data
* test specific scenarios that suit their needs
* familiarise themselves with how participants register
* check internal processes

## Access YAML format API specs

Provider development teams can also access the OpenAPI spec in YAML formats:

* [view the OpenAPI version 1 spec](https://npq-registration-separation-web.teacherservices.cloud/api/docs/v1/swagger.yaml)
* [view the OpenAPI version 2 spec](https://npq-registration-separation-web.teacherservices.cloud/api/docs/v2/swagger.yaml)
* [view the OpenAPI version 3 spec](https://npq-registration-separation-web.teacherservices.cloud/api/docs/v3/swagger.yaml)

Providers can use API testing tools such as Postman to make test API calls. Providers can import the API as a collection by using [Postman’s](https://www.postman.com/) import feature and copying in the YAML URL of the API spec.

### Rate limits

Providers are limited to 1,000 requests per 5 minutes when using the API in the production environment. If the limit is exceeded, providers will see `429` HTTP status codes.

This limit on requests for each authentication key is calculated on a rolling basis.

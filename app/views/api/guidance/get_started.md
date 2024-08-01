# Get started

## Connect to the API

Providers integrate their local CRM systems by connecting to this API's production and sandbox environments. 

## Request an authentication token

Providers need to use a unique authentication token to connect to the API. 

Emails us [INSERT EMAIL LINK] if you do not already have this token. We'll send it via secure email. 

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

<pre class="highlight plaintext" tabindex="0"><code>Authorization: Bearer {token}
</code></pre>

Unauthenticated requests will receive an <code>UnauthorizedResponse</code> with a <code>401</code> error code.

## Access YAML format API specs 

Provider development teams can also access the OpenAPI spec in YAML formats: 

* <a href="https://npq-registration-separation-web.teacherservices.cloud/api/docs/v1/swagger.yaml">view the OpenAPI version 1 spec</a>
* <a href="https://npq-registration-separation-web.teacherservices.cloud/api/docs/v2/swagger.yaml">view the OpenAPI version 2 spec</a>
* <a href="https://npq-registration-separation-web.teacherservices.cloud/api/docs/v3/swagger.yaml">view the OpenAPI version 3 spec</a>

Providers can use API testing tools such as Postman to make test API calls. Providers can import the API as a collection by using <a href="https://www.postman.com/">Postman’s</a> import feature and copying in the YAML URL of the API spec. 

## Production environment

The production environment is the live environment which processes real data: 

* <a href="https://npq-registration-web.teacherservices.cloud/api/v1">API version 1 production environment [LINK NOT YET LIVE]</a> 
* <a href="https://npq-registration-web.teacherservices.cloud/api/v2">API version 2 production environment [LINK NOT YET LIVE]</a> 
* <a href="https://npq-registration-web.teacherservices.cloud/api/v3">API version 3 production environment [LINK NOT YET LIVE]</a> 

Do not perform testing in the production environment. Real participant and payment data may be affected if you do this. 

### Rate limits

Providers are limited to 1,000 requests per 5 minutes when using the API in the production environment. If the limit is exceeded, providers will see `429` HTTP status codes. 
 
This limit on requests for each authentication key is calculated on a rolling basis. 
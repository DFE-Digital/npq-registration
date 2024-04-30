# Get started

## Connect to the API

Providers integrate their local CRM systems by connecting to this API's production and sandbox environments. 

## Request an authentication token

Providers need to use a unique authentication token to connect to the API. 

Emails us [INSERT EMAIL LINK]if you do not already have this token. We'll send it via secure email. 

The tokens do not expire. 

[WARNING TEXT] Providers must not share tokens in publicly accessible documents or repositories. 

### How to use an authentication token 

Include an authentication token in all requests to the API by adding an <code>Authorization</code> request header (not as part of the URL) in the following format: 

[HIGHLIGHT] <code>Authorization: Bearer {token} </code>

Unauthenticated requests will receive an <code>UnauthorizedResponse</code> with a <code>401</code> error code.

## Access YAML format API specs 

Provider development teams can also access the OpenAPI spec in YAML formats: 

* view the OpenAPI v1.0.0. spec [ADD LINK]
* view the OpenAPI v2.0.0. spec [ADD LINK]
* view the OpenAPI v3.0.0. spec [ADD LINK]

Providers can use API testing tools such as Postman to make test API calls. Providers can import the API as a collection by using Postman’s [ADD LINK] import feature and copying in the YAML URL of the API spec. 

## Production environment

The production environment is the live environment which processes real data: 

* API v1 [ADD LINK]
* API v2 [ADD LINK]
* API v3 [ADD LINK]

Do not perform testing in the production environment. Real participant and payment data may be affected if you do this. 

### Rate limits

Providers are limited to 1,000 requests per 5 minutes when using the API in the production environment. If the limit is exceeded, providers will see <code>429</code> HTTP status codes. 
 
This limit on requests for each authentication key is calculated on a rolling basis. 
[< Back to Navigation](../README.md)

# Get an Identity

The Get an Identity service is integrated into the NPQ application to abstract identity verification away from the NPQ application. This allows the NPQ application to be agnostic of the identity verification process and allows the identity verification process to be changed without affecting the NPQ application.

## Omniauth Login

The Get an Identity service is integrated into the NPQ app as an oauth provider called `tra_openid_connect`, the strategy for which is set up in [Omniauth::Strategies::TraOpenidConnect](../lib/omniauth/strategies/tra_openid_connect.rb).

The GetAnIdentity provider implements the OpenId protocol with pkce enabled, details of which are available [here](https://openid.net/specs/openid-connect-core-1_0.html). The auth flow specifically detailed in [this section](https://openid.net/specs/openid-connect-core-1_0.html#CodeFlowAuth).

This handshaking is handled by the omniauth and omniauth-oauth2, with the specifics of this protocol detailde in the strategy linked above.

Upon login a user record is linked to the `get_an_identity_id` provided by the Get an Identity service. This allows the NPQ application to identify the user in the future. For emails in use prior to the Get an Identity integration, the user record with the email address provided by the Get an Identity service is assigned the `get_an_identity_id`. Otherwise a new user is created. This is handled in the [OmniauthController](../app/controllers/users/omniauth_controller.rb).

The user is then logged in and can proceed onwwards.

## Webhooks

The Get an Identity service provides a webhook to notify the NPQ application of changes to a user's identity verification status and to their personal details. This is handled in the [Api::V1::GetAnIdentity::WebhookMessagesController](../app/controllers/api/v1/get_an_identity/webhook_messages_controller.rb).

Messages are stored immediately upon being received and are processed in the background by the [GetAnIdentity::ProcessWebhookMessageJob](../app/jobs/get_an_identity/process_webhook_message_job.rb). This job is enqueued by the [GetAnIdentity::WebhookMessage](../app/models/get_an_identity/webhook_message.rb) model.

Different messages are supported by different handlers, which are provided by the message model itself via `processor_klass` method.

Documentation on the different messages can be found at https://github.com/DFE-Digital/get-an-identity/blob/main/docs/webhooks.md.

### Currently supported Webhooks

- UserUpdated via [Services::GetAnIdentity::Webhooks::UserUpdatedProcessor](../app/services/get_an_identity/webhooks/user_updated_processor.rb)

[< Back to Navigation](../README.md)

# Get an Identity

1. [What was Get an Identity?](#what-is-get-an-identity)
1. [Omniauth Login](#omniauth-login)
1. [Webhooks](#webhooks)

# What was Get an Identity?

The Get an Identity service was integrated into the NPQ application to abstract identity verification away from the NPQ application. This allowed the NPQ application to be agnostic of the identity verification process and allows the identity verification process to be changed without affecting the NPQ application.
It has since been replaced by [TeacherAuth](one_login_and_teacher_auth.md).

## Omniauth Login

The Get an Identity service was integrated into the NPQ app as an OAuth provider called `tra_openid_connect`, the strategy for which is set up in [Omniauth::Strategies::TraOpenidConnect](../lib/omniauth/strategies/tra_openid_connect.rb).

The GetAnIdentity provider implements the OpenId protocol with pkce enabled, details of which are available [here](https://openid.net/specs/openid-connect-core-1_0.html). The auth flow specifically detailed in [this section](https://openid.net/specs/openid-connect-core-1_0.html#CodeFlowAuth).

This handshaking is handled by the omniauth and omniauth-oauth2, with the specifics of this protocol detailde in the strategy linked above.

Upon login a user record was linked to the `get_an_identity_id` provided by the Get an Identity service. This allowed the NPQ application to identify the user in the future. For emails in use prior to the Get an Identity integration, the user record with the email address provided by the Get an Identity service was assigned the `get_an_identity_id`, otherwise a new user was created. This was handled in the [OmniauthController](../app/controllers/users/omniauth_controller.rb).

The user was then logged in and could proceed onwwards.

## Webhooks

_These webhooks have been removed from the codebase - the information here is for historical reference only._

The Get an Identity service provided a webhook to notify the NPQ application of changes to a user's identity verification status and to their personal details.

Messages were stored immediately upon being received and were processed in the background by the `GetAnIdentity::ProcessWebhookMessageJob` job, which has since been moved to [TeachingRecordSysten::ProcessWebhookMessageJob](../app/jobs/teaching_record_system/process_webhook_message_job.rb). This job was enqueued by the `GetAnIdentity::WebhookMessage` model, which has since moved to the [WebhookMessage](../app/models/webhook_message.rb) model.

Different messages were supported by different handlers, which were provided by the message model itself via `processor_klass` method.

Documentation on the different messages can be found at https://github.com/DFE-Digital/get-an-identity/blob/main/docs/webhooks.md.

### Previously supported Webhooks

- UserUpdated via [GetAnIdentityService::Webhooks::UserUpdatedProcessor](https://github.com/DFE-Digital/npq-registration/blob/f52c6b2742122a8e0d2b0fb92acc10e6574da380/app/services/get_an_identity_service/webhooks/user_updated_processor.rb)

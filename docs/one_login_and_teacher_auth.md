[< Back to Navigation](../README.md)

# OneLogin and TeacherAuth

The NPQ service integrates directly with DfE's TeacherAuth authentication service and indirectly with GDS's OneLogin authentication service via TeacherAuth.

## OneLogin

[OneLogin](https://www.sign-in.service.gov.uk/) is a common governmental OIDC authentication service provided by GDS used by many [government services](https://home.account.gov.uk/services-using-one-login) for identity and authentication.

This supports multiple levels of identity checks, with the enhanced checks requiring use of the app and a biometric id (eg a passport), with alternative non-digital approval processes available (eg at Post Offices).

## TeacherAuth

TeacherAuth is a DfE OIDC service to link a users teaching record with their OneLogin account. NPQ integrates directly with TeacherAuth, to handle authentication and provide an identity we either match to an existing NPQ user account, or use to create a new NPQ user account.

The TeacherAuth service in turn wraps the OneLogin OIDC service, requiring enhanced verification checks to ensure the users identity is proven. A user signs in via OneLogin and TeacherAuth adds additional screens to the OIDC flow to allow a user to be matched to their teaching record.

If a user has a teaching record then their TRN (teaching record number) will be included with the OIDC extra info provided to the NPQ service during sign in.

If a user does not have a teaching record, then sufficient additional information to allow the creation of a future teaching record will be captured during the TeacherAuth sign in flow. Creation of a teaching record will be triggered by NPQ once a user is accepted onto a course.

Notably, there may be multiple OneLogin accounts all linking back to the same teaching record (with multiple OneLogin UIDs returning the same TRN in the OIDC extra info).

### Support tickets

There is is an edge case where the TeacherAuth system may determine that a user is likely to correspond to an existing Teaching Record but has not reached the provenance threshold to be automatically linked.

In this scenario, the sign in process is stopped and a support ticket is created for manual review by the support desk, and the user is not returned to NPQ.

The user needs to wait for the support desk to process their support ticket, at which point the user will be notified via email, and they can then start NPQ registration again - this time passing straight through TeacherAuth.

## NPQ user authentication

The NPQ digital service has had 3 authentication mechanisms during its deployment.

1. Originally, it had its own internal devise based authentication process
2. Subsequently it moved to using DfE's Teacher ID (aka [Get an Identity](get_an_identity.md) OIDC service.
3. And now it uses DfE's TeacherAuth OIDC service (wrapping OneLogin), via OmniAuth.

During the sign in process, a TeacherAuth user is matched to an NPQ user by either, UID or TRN.

### UID

The provider and UID pair - this is tied to a specific TeacherAuth account and used to match up with the User#uid field in the NPQ database.

### TRN

A user can also be matched via their TRN, this allows continued access to existing NPQ accounts from newly created TeacherAuth accounts. For this to occur, the NPQ account must have a previously verified TRN, and the TeacherAuth account must include a TRN.

In theory, this can cause 'flip flopping' when a user has multiple TeacherAuth accounts all linked to the same teaching record and the NPQ account 'flip-flops' between the TeacherAuth account it is attached to. In practice, it is highly unlikely that a user will be interacting with the NPQ service via multiple TeacherAuth accounts in the same timeframe and is more likely that they have moved between different accounts over time and it means the NPQ account follows their Teaching Record (which is the ultimate concept if identity) rather than their Teacher Auth account (which they may have multiples of).

## TRN allocation for users without TRNs

If a user does not already have an TRN, the TeacherAuth will have captured sufficient information to create a future teaching record - referred to as a 'dormant trn request'.

When the user is accepted onto a course, then an API call is made to 'Activate' their TRN request (see [TeachingRecordSystem::AllocateTrnJob](../app/jobs/teaching_record_system/allocated_trn_job.rb)). In most cases this immediately returns a TRN and it is assigned to the user. For a minority though it may take up to a few days, in which case the NPQ service is notified by TRS of the new TRN via a webhook.

## Webhooks

The Teaching Record System service provides a webhook to notify the NPQ application of changes to a Teaching Record. This is handled in the [Api::V1::TeachingRecordSystem::WebhookMessagesController](../app/controllers/api/v1/teaching_record_system/webhook_messages_controller.rb).

Messages are stored immediately upon being received and are processed in the background by the [TeachingRecordSystem::ProcessWebhookMessageJob](../app/jobs/teaching_record_system/process_webhook_message_job.rb). This job is enqueued by the [WebhookMessage](../app/models/webhook_message.rb) model.

Different messages are supported by different handlers, which are provided by the message model itself via `processor_klass` method.

### Currently supported Webhooks

- TrnRequestCompletedProcessor via [TeachingRecordSystem::Webhooks::TrnRequestCompletedProcessor](../app/services/teaching_record_system/webhooks/trn_request_completed_processor.rb)
  Updates the TRN on an NPQ account linked to a TeacherAuth account when TRS links a TeacherAuth account to a Teaching Record. This will also merge multiple historic user accounts with the same verified TRN.
- UserUpdatedProcessor via [TeachingRecordSystem::Webhooks::UserUpdatedProcessor](../app/services/teaching_record_system/webhooks/user_updated_processor.rb)
  Updates the TRN on an NPQ account linked to a TeacherAuth account when the TeacherAuth account is updated. This will also merge multiple historic user accounts with the same verified TRN.
  _This overlaps with the TrnRequestCompleted webhook but also provides an email and could potentially be used to keep our record of email address current in the future_
- PersonDeactivatedProcessor via [TeachingRecordSystem::Webhooks::PersonDeactivatedProcessor](../app/services/teaching_record_system/webhooks/person_deactivated_processor.rb)
  If two Teaching Records are determined to be duplicates, one will be deactivated and the TeacherAuth account will be linked to the other - with the TeacherAuth accounts TRN changing. This webhook will notify us of the new trn. If that TRN corresponds to other NPQ accounts then those will be merged into this NPQ account and archived.

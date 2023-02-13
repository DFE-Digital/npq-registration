class GetAnIdentityIdSyncJob < ApplicationJob
  # Set as low priority so that these jobs don't block other time sensitive issue
  queue_as :low_priority

  def perform(user:)
    if user.get_an_identity_id.blank?
      create_skipped_ecf_sync_request_log(user:)
      return false
    end

    ecf_user = user.ecf_user

    if ecf_user.get_an_identity_id == user.get_an_identity_id
      create_successful_ecf_sync_request_log(user:, message: "User's get_an_identity_id already synced to ECF")
    else
      # Sync get_an_identity_id to ECF
      ecf_user.update!(get_an_identity_id: user.get_an_identity_id)

      create_successful_ecf_sync_request_log(user:, message: "User's get_an_identity_id synced to ECF")
    end

    # Mark user as synced so that this user gets skipped in future sync runs
    user.update_column(:get_an_identity_id_synced_to_ecf, true)
  rescue StandardError => e
    create_failed_ecf_sync_request_log(user:, error: e)

    # Re-raise to fail the job, we don't want to continue if we couldn't confirm the existence
    # or non-existence of an ECF user, a failure indicates some sort of communication issue and we should
    # retry the job later.
    Sentry.with_scope do |scope|
      scope.set_context("User", { id: user.id, get_an_identity_id: user.get_an_identity_id, ecf_id: user.ecf_id })
      raise e
    end
  end

private

  def create_successful_ecf_sync_request_log(user:, message:)
    EcfSyncRequestLog.create!(
      sync_type: :get_an_identity_id_sync,
      syncable: user,
      status: :success,
      error_messages: [message],
    )
  end

  def create_failed_ecf_sync_request_log(user:, error:)
    env = error.try(:env) || {}
    response_body = env["response_body"]
    EcfSyncRequestLog.create!(
      sync_type: :get_an_identity_id_sync,
      syncable: user,
      status: :failed,
      error_messages: ["#{error.class} - #{error.message}"],
      response_body:,
    )
  end

  def create_skipped_ecf_sync_request_log(user:)
    EcfSyncRequestLog.create!(
      sync_type: :get_an_identity_id_sync,
      syncable: user,
      status: :failed,
      error_messages: ["User does not have a get_an_identity_id"],
    )
  end
end

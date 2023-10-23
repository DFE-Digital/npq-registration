class GetAnIdentityDataSyncJob < ApplicationJob
  # Set as low priority so that these jobs don't block other time sensitive issue
  queue_as :low_priority

  def perform(user:)
    return if user.get_an_identity_id.blank?

    update_user_from_get_an_identity(user)
    sync_user_update_to_ecf(user)
  end

private

  def update_user_from_get_an_identity(user)
    GetAnIdentity::UserUpdater.call(user:)
  end

  def sync_user_update_to_ecf(user)
    Ecf::EcfUserUpdater.call(user:)
  end
end

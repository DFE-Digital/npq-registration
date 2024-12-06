class GetAnIdentityDataSyncJob < ApplicationJob
  # Set as low priority so that these jobs don't block other time sensitive issue
  queue_as :low_priority

  def perform(user:)
    return if user.get_an_identity_id.blank?

    update_user_from_get_an_identity(user)
  end

private

  def update_user_from_get_an_identity(user)
    GetAnIdentityService::UserUpdater.call(user:)
  end
end

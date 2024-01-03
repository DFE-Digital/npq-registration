class EcfUserUpdaterJob < ApplicationJob
  # Set as low priority so that these jobs don't block other time sensitive issue
  queue_as :low_priority

  def perform(user:)
    Ecf::EcfUserUpdater.new(user:).call if user.ecf_id.present?
  end
end

class ApplicationSynchronizationJob < ApplicationJob
  queue_as :default
  def perform
    ECF::EcfApplicationSynchronization.new.call
  end
end

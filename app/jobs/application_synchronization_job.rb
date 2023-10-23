class ApplicationSynchronizationJob < ApplicationJob
  queue_as :default
  def perform
    Ecf::EcfApplicationSynchronization.new.call
  end
end

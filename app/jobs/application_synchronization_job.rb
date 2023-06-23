class ApplicationSynchronizationJob < ApplicationJob
  queue_as :default
  def perform
    Services::Ecf::EcfApplicationSynchronizationService.new.call
  end
end

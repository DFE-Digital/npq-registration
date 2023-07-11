class ApplicationSynchronizationJob < ApplicationJob
  queue_as :default
  def perform
    Services::Ecf::EcfApplicationSynchronization.new.call
  end
end

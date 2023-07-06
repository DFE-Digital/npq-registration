class SyncApplicationStatusJob < ApplicationJob
  queue_as :default
  def perform(data)
    Services::Ecf::ApplicationUpdater.new(data).call
  end
end

class NpqApplicationUpdaterJob < ApplicationJob
  queue_as :default
  def perform(data)
    Services::Ecf::NpqApplicationUpdater.new(data).call
  end
end

class NpqApplicationUpdaterJob < ApplicationJob
  queue_as :default
  def perform(response_data)
    Services::Ecf::NpqApplicationUpdater.new(response_data).call
  end
end

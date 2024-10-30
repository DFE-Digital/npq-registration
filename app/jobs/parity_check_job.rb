class ParityCheckJob < ApplicationJob
  queue_as :migration

  def perform
    parity_check = Migration::ParityCheck.new
    parity_check.run!
  end
end

class ParityCheckJob < ApplicationJob
  queue_as :high_priority

  def perform
    parity_check = Migration::ParityCheck.new
    parity_check.run!
  end
end

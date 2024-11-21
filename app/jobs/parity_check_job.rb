class ParityCheckJob < ApplicationJob
  def perform
    parity_check = Migration::ParityCheck.new
    parity_check.run!
  end
end

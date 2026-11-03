class BrokenJob < ApplicationJob
  def perform
    raise "Retriable ActiveJob"
  end
end

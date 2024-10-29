class MigrationJob < ApplicationJob
  queue_as :high_priority

  def max_attempts
    1
  end

  def perform
    migrator = Migration::Coordinator.new
    migrator.migrate!
  end
end

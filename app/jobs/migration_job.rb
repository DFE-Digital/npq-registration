class MigrationJob < ApplicationJob
  queue_as :high_priority

  def perform
    migrator = Migration::Coordinator.new
    migrator.migrate!
  end
end

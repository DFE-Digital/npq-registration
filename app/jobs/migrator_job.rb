class MigratorJob < ApplicationJob
  queue_as :high_priority

  def max_attempts
    1
  end

  def perform(migrator:, worker:)
    migrator.call(worker:)
  end
end

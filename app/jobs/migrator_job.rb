class MigratorJob < ApplicationJob
  queue_as :migration

  def max_attempts
    1
  end

  def perform(migrator:, worker:)
    migrator.call(worker:)
  end
end

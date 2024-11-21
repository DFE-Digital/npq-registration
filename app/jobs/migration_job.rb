class MigrationJob < ApplicationJob
  queue_as :migration

  discard_on StandardError do |_job, exception|
    Sentry.capture_exception(exception)
  end

  def perform
    migrator = Migration::Coordinator.new
    migrator.migrate!
  end
end

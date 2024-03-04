class MigrationJob < ApplicationJob
  def perform
    migrator = Migration::Migrator.new
    migrator.migrate!
  end
end

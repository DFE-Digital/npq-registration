module Migration
  class Migrator
    class UnsupportedEnvironmentError < RuntimeError; end
    class MigrationNotPreparedError < RuntimeError; end

    MIGRATORS = [
      Migration::Migrators::LeadProvider,
      Migration::Migrators::Cohort,
      Migration::Migrators::Statement,
      Migration::Migrators::User,
      Migration::Migrators::School,
      Migration::Migrators::Course,
      Migration::Migrators::Application,
    ].freeze

    def migrate!
      check_environment!

      run_migrations
    end

  private

    def check_environment!
      migration_enabled = Rails.application.config.npq_separation[:migration_enabled]

      raise UnsupportedEnvironmentError, "The migration functionality is disabled for this environment" unless migration_enabled
    end

    def run_migrations
      MIGRATORS.each do |migrator|
        next if DataMigration.where(model: migrator.model).exists?

        migrator.prepare!
        migrator.call
      end
    end
  end
end

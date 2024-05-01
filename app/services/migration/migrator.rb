module Migration
  class Migrator
    class UnsupportedEnvironmentError < RuntimeError; end
    class MigrationAlreadyRanError < RuntimeError; end
    class MigrationNotPreparedError < RuntimeError; end
    class MigrationAlreadyPreparedError < RuntimeError; end

    MIGRATORS = [
      Migration::Migrators::LeadProvider,
      Migration::Migrators::Cohort,
      Migration::Migrators::Statement,
      Migration::Migrators::User,
      Migration::Migrators::School,
      Migration::Migrators::Course,
      Migration::Migrators::Application,
      Migration::Migrators::ApplicationNotInEcf,
    ].freeze

    class << self
      def prepare_for_migration
        raise MigrationAlreadyPreparedError, "The migration has already been prepared" if DataMigration.exists?

        MIGRATORS.each(&:prepare!)
      end
    end

    def migrate!
      check_environment!
      prevent_multiple_migrations!
      check_migration_prepared!

      run_migration
    end

  private

    def prevent_multiple_migrations!
      raise MigrationAlreadyRanError, "The migration has already been run" if DataMigration.not_pending.exists?
    end

    def check_migration_prepared!
      raise MigrationNotPreparedError, "The migration has not been prepared" unless DataMigration.pending.exists?
    end

    def check_environment!
      migration_enabled = Rails.application.config.npq_separation[:migration_enabled]

      raise UnsupportedEnvironmentError, "The migration functionality is disabled for this environment" unless migration_enabled
    end

    def run_migration
      MIGRATORS.each(&:call)
    end
  end
end

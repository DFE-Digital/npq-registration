module Migration
  class Coordinator
    class UnsupportedEnvironmentError < RuntimeError; end
    class MigrationAlreadyPreparedError < RuntimeError; end

    class << self
      def prepare_for_migration
        raise MigrationAlreadyPreparedError, "The migration has already been prepared" if DataMigration.exists?

        Migration::Migrators::Base.flush_cache!

        migrators.each(&:prepare!)
      end

      def migrators
        Rails.application.eager_load! # As we are using descendants
        Migration::Migrators::Base.descendants.sort_by(&:name)
      end
    end

    def migrate!
      check_environment!

      run_migration
    end

  private

    def check_environment!
      migration_enabled = Rails.application.config.npq_separation[:migration_enabled]

      raise UnsupportedEnvironmentError, "The migration functionality is disabled for this environment" unless migration_enabled
    end

    def run_migration
      next_runnable_migrator = self.class.migrators.select(&:runnable?).first

      return unless next_runnable_migrator

      next_runnable_migrator.warm_cache
      next_runnable_migrator.queue
    end
  end
end

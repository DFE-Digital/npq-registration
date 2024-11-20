module Migration
  class Coordinator
    class UnsupportedEnvironmentError < RuntimeError; end
    class MigrationAlreadyPreparedError < RuntimeError; end

    class << self
      def prepare_for_migration
        raise MigrationAlreadyPreparedError, "The migration has already been prepared" if DataMigration.exists?

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
      raise UnsupportedEnvironmentError, "The migration functionality is disabled for this environment" unless Feature.ecf_api_disabled?
    end

    def run_migration
      Delayed::Job.with_advisory_lock("queue_next_migrators") do
        next_runnable_migrators = self.class.migrators.select(&:runnable?)

        return unless next_runnable_migrators.any?

        next_runnable_migrators.each(&:queue)
      end
    end
  end
end

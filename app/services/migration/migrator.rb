module Migration
  class Migrator
    class UnsupportedEnvironmentError < RuntimeError; end
    class MigrationAlreadyRanError < RuntimeError; end
    class MigrationNotPreparedError < RuntimeError; end

    MODELS_TO_MIGRATE = %i[lead_provider cohort statement].freeze

    class << self
      def prepare_for_migration
        Migration::DataMigration.create!(MODELS_TO_MIGRATE.map { |model| { model: } })
      end
    end

    def migrate!
      check_environment!
      check_migration_prepared!
      prevent_multiple_migrations!

      run_dummy_migration
    end

  private

    def data_migrations
      @data_migrations ||= Migration::DataMigration.all
    end

    def prevent_multiple_migrations!
      raise MigrationAlreadyRanError, "The migration has already been run" unless data_migrations.all?(&:pending?)
    end

    def check_migration_prepared!
      raise MigrationNotPreparedError, "The migration has not been prepared" if data_migrations.blank?
    end

    def check_environment!
      migration_enabled = Rails.application.config.npq_separation[:migration_enabled]

      raise UnsupportedEnvironmentError, "The migration functionality is disabled for this environment" unless migration_enabled
    end

    def run_dummy_migration
      data_migrations.each { |data_migration| simulate_model_migration(data_migration) }
    end

    def simulate_model_migration(data_migration)
      data_migration.update!(started_at: Time.zone.now, total_count: rand(1...1000))

      data_migration.total_count.times do |processed_count|
        # Up to 1 minute of processing time/model
        sleep(rand(0.001...0.06))

        data_migration.update!(processed_count:)

        record_failure = rand(1...25) == 1
        data_migration.update!(failure_count: data_migration.failure_count + 1) if record_failure
      end

      data_migration.update!(completed_at: Time.zone.now)
    end
  end
end

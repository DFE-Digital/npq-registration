module Migration
  class Migrator
    class UnsupportedEnvironmentError < RuntimeError; end

    MODELS_TO_MIGRATE = %i[lead_provider cohort statement].freeze

    def migrate!
      check_environment!
      initialize_dummy_migration
      run_dummy_migration
    end

  private

    attr_accessor :data_migrations

    def check_environment!
      migration_enabled = Rails.application.config.npq_separation[:migration_enabled]

      raise UnsupportedEnvironmentError, "The migration functionality is disabled for this environment" unless migration_enabled
    end

    def initialize_dummy_migration
      self.data_migrations = MODELS_TO_MIGRATE.index_with { |model| Migration::DataMigration.create!(model:) }
    end

    def run_dummy_migration
      MODELS_TO_MIGRATE.each { |model| simulate_model_migration(model) }
    end

    def simulate_model_migration(model)
      data_migrations[model].update!(started_at: Time.zone.now)

      rand(1...1000).times do |processed_count|
        # Up to 1 minute of processing time/model
        sleep(rand(0.001...0.06))

        data_migrations[model].update!(processed_count:)

        record_failure = rand(1...50) == 50
        data_migrations[model].update!(failure_count: data_migrations[model].failure_count + 1) if record_failure
      end

      data_migrations[model].update!(completed_at: Time.zone.now)
    end
  end
end

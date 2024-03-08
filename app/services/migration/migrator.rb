module Migration
  class Migrator
    class UnsupportedEnvironmentError < RuntimeError; end
    class MigrationAlreadyRanError < RuntimeError; end
    class MigrationNotPreparedError < RuntimeError; end
    class MigrationAlreadyPreparedError < RuntimeError; end

    class << self
      def prepare_for_migration
        raise MigrationAlreadyPreparedError, "The migration has already been prepared" if DataMigration.exists?

        DataMigration.create!(model: :lead_provider)
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
      migrate_lead_providers
    end

    def migrate_lead_providers
      data_migration = DataMigration.find_by(model: :lead_provider)

      data_migration.update!(started_at: Time.zone.now, total_count: ecf_npq_lead_providers.count)

      ecf_npq_lead_providers.find_each do |ecf_npq_lead_provider|
        data_migration.increment!(:processed_count)
        npq_lead_provider = LeadProvider.find_by(ecf_id: ecf_npq_lead_provider.id)

        data_migration.increment!(:failure_count) unless npq_lead_provider
      end

      data_migration.update!(completed_at: Time.zone.now)
    end

    def ecf_npq_lead_providers
      @ecf_npq_lead_providers ||= Ecf::NpqLeadProvider.all
    end
  end
end

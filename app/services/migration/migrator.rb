module Migration
  class Migrator
    class UnsupportedEnvironmentError < RuntimeError; end
    class MigrationAlreadyRanError < RuntimeError; end
    class MigrationNotPreparedError < RuntimeError; end
    class MigrationAlreadyPreparedError < RuntimeError; end

    class << self
      MODELS_TO_BE_MIGRATED = %i[lead_provider cohort statement].freeze

      def prepare_for_migration
        raise MigrationAlreadyPreparedError, "The migration has already been prepared" if DataMigration.exists?

        MODELS_TO_BE_MIGRATED.each { |model| DataMigration.create!(model:) }
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
      migrate_cohorts
      migrate_statements
    end

    def migrate(items, model)
      data_migration = DataMigration.find_by(model:)
      data_migration.update!(started_at: Time.zone.now, total_count: items.count)

      failure_manager = FailureManager.new(data_migration:)

      items.each do |item|
        data_migration.increment!(:processed_count)
        begin
          yield(item)
        rescue ActiveRecord::ActiveRecordError => e
          data_migration.increment!(:failure_count)
          failure_manager.record_failure(item, e.message)
        end
      end

      data_migration.update!(completed_at: Time.zone.now)
    end

    def migrate_lead_providers
      migrate(ecf_npq_lead_providers, :lead_provider) do |ecf_npq_lead_provider|
        LeadProvider.find_by!(ecf_id: ecf_npq_lead_provider.id)
      end
    end

    def ecf_npq_lead_providers
      @ecf_npq_lead_providers ||= Ecf::NpqLeadProvider.all
    end

    def ecf_cohorts
      @ecf_cohorts ||= Ecf::Cohort.where(start_year: 2021..)
    end

    def migrate_cohorts
      migrate(ecf_cohorts, :cohort) do |ecf_cohort|
        cohort = Cohort.find_or_initialize_by(start_year: ecf_cohort.start_year)
        cohort.update!(registration_start_date: ecf_cohort.npq_registration_start_date.presence || ecf_cohort.registration_start_date)
      end
    end

    def ecf_statements
      @ecf_statements ||= Ecf::Finance::Statement.all
    end

    def migrate_statements
      migrate(ecf_statements, :statement) do |ecf_statement|
        statement = Statement.find_or_initialize_by(month: Date::MONTHNAMES.find_index(ecf_statement.name.split[0]), year: ecf_statement.name.split[1])

        statement.update!(
          deadline_date: ecf_statement.deadline_date,
          payment_date: ecf_statement.payment_date,
          output_fee: ecf_statement.output_fee,
          cohort: Cohort.find_by(start_year: ecf_cohorts.find_by(id: ecf_statement.cohort_id).start_year),
          lead_provider: LeadProvider.find_by(ecf_id: ecf_statement.cpd_lead_provider.npq_lead_provider.id),
          marked_as_paid_at: ecf_statement.marked_as_paid_at,
          reconcile_amount: ecf_statement.reconcile_amount,
          state: if ecf_statement.type == "Finance::Statement::NPQ::Payable"
                   :payable
                 else
                   ecf_statement.type == "Finance::Statement::NPQ::Paid" ? :paid : :open
                 end,
          ecf_id: ecf_statement.id,
        )
      end
    end
  end
end

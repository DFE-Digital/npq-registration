module Migration::Migrators
  class Base
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :worker

    class << self
      def call(args = {})
        new(**args).call
      end

      def queue
        Migration::DataMigration.where(model:).update!(queued_at: Time.zone.now)

        number_of_workers.times do |worker|
          MigratorJob.perform_later(migrator: self, worker:)
        end
      end

      def prepare!
        model = name.gsub(/^.*::/, "").underscore.to_sym
        number_of_workers.times do |worker|
          data_migration = Migration::DataMigration.create!(model:, worker:)
          Migration::FailureManager.purge_failures!(data_migration)
        end
      end

      def runnable?
        Migration::DataMigration.incomplete.where(model: dependencies).none? &&
          Migration::DataMigration.queued.where(model:).none?
      end

      def record_count
        raise NotImplementedError
      end

      def model
        raise NotImplementedError
      end

      def dependencies
        []
      end

      def number_of_workers
        [1, (record_count / records_per_worker.to_f).ceil].max
      end

      def records_per_worker
        10_000
      end
    end

  protected

    def migrate(items)
      items = items.order(:id).offset(offset).limit(limit)

      start_migration!(items.count)

      # As we're using offset/limit, we can't use find_each!
      items.each do |item|
        yield(item)
        Migration::DataMigration.update_counters(data_migration.id, processed_count: 1)
      rescue ActiveRecord::ActiveRecordError => e
        Migration::DataMigration.update_counters(data_migration.id, failure_count: 1, processed_count: 1)
        failure_manager.record_failure(item, e.message)
      end

      finalise_migration!
    end

    def run_once
      yield if worker.zero?
    end

    def failure_manager
      @failure_manager ||= Migration::FailureManager.new(data_migration:)
    end

    def data_migration
      @data_migration ||= Migration::DataMigration.find_by(model: self.class.model, worker:)
    end

    def find_lead_provider!(ecf_id:)
      lead_providers_by_ecf_id[ecf_id] || raise(ActiveRecord::RecordNotFound, "Couldn't find LeadProvider")
    end

    def find_cohort!(start_year:)
      cohorts_by_start_year[start_year] || raise(ActiveRecord::RecordNotFound, "Couldn't find Cohort")
    end

    def find_application!(ecf_id:)
      applications_by_ecf_id[ecf_id] || raise(ActiveRecord::RecordNotFound, "Couldn't find Application")
    end

    def find_declaration!(ecf_id:)
      declarations_by_ecf_id[ecf_id] || raise(ActiveRecord::RecordNotFound, "Couldn't find Declaration")
    end

    def find_statement!(ecf_id:)
      statements_by_ecf_id[ecf_id] || raise(ActiveRecord::RecordNotFound, "Couldn't find Statement")
    end

  private

    def statements_by_ecf_id
      @statements_by_ecf_id ||= ::Statement.select(:id, :ecf_id).all.index_by(&:ecf_id)
    end

    def declarations_by_ecf_id
      @declarations_by_ecf_id ||= ::Declaration.all.index_by(&:ecf_id)
    end

    def applications_by_ecf_id
      @applications_by_ecf_id ||= ::Application.select(:id, :ecf_id).all.index_by(&:ecf_id)
    end

    def lead_providers_by_ecf_id
      @lead_providers_by_ecf_id ||= ::LeadProvider.select(:id, :ecf_id).all.index_by(&:ecf_id)
    end

    def cohorts_by_start_year
      @cohorts_by_start_year ||= ::Cohort.select(:id, :start_year).all.index_by(&:start_year)
    end

    def offset
      worker * self.class.records_per_worker
    end

    def limit
      self.class.records_per_worker
    end

    def start_migration!(total_count)
      # We reset the processed/failure counts in case this is a retry.
      data_migration.update!(
        started_at: Time.zone.now,
        total_count:,
        processed_count: 0,
        failure_count: 0,
      )
      log_info("Migration started")
    end

    def log_info(message)
      migration_details = data_migration.reload.attributes.slice(
        "model",
        "worker",
        "processed_count",
        "total_count",
      ).symbolize_keys
      Rails.logger.info(message, migration_details)
    end

    def finalise_migration!
      data_migration.update!(completed_at: 1.second.from_now)
      log_info("Migration completed")

      return unless Migration::DataMigration.incomplete.where(model: self.class.model).none?

      # Queue a follow up migration to migrate any
      # dependent models.
      MigrationJob.perform_later
    end
  end
end

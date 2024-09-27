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

        warm_cache

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
        5_000
      end

      def flush_cache!
        warm_cache_methods.each do |m|
          key = m.chomp("_warm_cache")
          Rails.cache.delete(key)
          Rails.cache.delete("#{key}_already_cached")
        end
      end

      def warm_cache
        dependencies.each do |dependency|
          cache_to_warm = warm_cache_methods.select { |key| key.include?(dependency.to_s) }
          cache_to_warm.each(&method(:send))
        end
      end

      def warm_cache_methods
        methods.map(&:to_s).select { |m| m.include?("_warm_cache") }
      end

      def lead_provider_by_ecf_id_warm_cache
        cache_write(:lead_provider_by_ecf_id) { ::LeadProvider.pluck(:ecf_id, :id).to_h }
      end

      def course_by_identififer_warm_cache
        cache_write(:course_by_identifier) { ::Course.pluck(:identifier, :id).to_h }
      end

      def course_by_ecf_id_warm_cache
        cache_write(:course_by_ecf_id) { ::Course.pluck(:ecf_id, :id).to_h }
      end

      def statement_by_ecf_id_warm_cache
        cache_write(:statement_by_ecf_id) { ::Statement.pluck(:ecf_id, :id).to_h }
      end

      def declaration_by_ecf_id_warm_cache
        cache_write(:declaration_by_ecf_id) { ::Declaration.pluck(:ecf_id, :id).to_h }
      end

      def application_by_ecf_id_warm_cache
        cache_write(:application_by_ecf_id) { ::Application.pluck(:ecf_id, :id).to_h }
      end

      def user_by_ecf_id_warm_cache
        cache_write(:user_by_ecf_id) { ::User.pluck(:ecf_id, :id).to_h }
      end

      def cohort_by_ecf_id_warm_cache
        cache_write(:cohort_by_ecf_id) { ::Cohort.pluck(:ecf_id, :id).to_h }
      end

      def schedule_by_ecf_id_warm_cache
        cache_write(:schedule_by_ecf_id) { ::Schedule.pluck(:ecf_id, :id).to_h }
      end

      def school_by_urn_warm_cache
        cache_write(:school_by_urn) { ::School.pluck(:urn, :id).to_h }
      end

      def private_childcare_provider_by_urn_warm_cache
        cache_write(:private_childcare_provider_by_urn) { ::PrivateChildcareProvider.including_disabled.pluck(:provider_urn, :id).to_h }
      end

      def itt_provider_by_legal_name_and_operating_name_warm_cache
        cache_write(:itt_provider_by_legal_name_and_operating_name) do
          providers = ::IttProvider.including_disabled
          providers_by_legal_name = providers.pluck(:legal_name, :id).to_h.transform_keys(&:downcase)
          providers_by_operating_name = providers.pluck(:operating_name, :id).to_h.transform_keys(&:downcase)
          providers_by_legal_name.merge!(providers_by_operating_name)
        end
      end

      def cache_write(prefix, &block)
        already_cached_key = "#{prefix}_already_cached"
        return if Rails.cache.read(already_cached_key)

        Rails.cache.write(prefix, block.call, expires_in: 1.hour)
        Rails.cache.write(already_cached_key, true, expires_in: 1.hour)
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

    def find_lead_provider_id!(ecf_id:)
      @lead_provider_by_ecf_id ||= Rails.cache.read(:lead_provider_by_ecf_id)
      @lead_provider_by_ecf_id[ecf_id] || raise(ActiveRecord::RecordNotFound, "Couldn't find LeadProvider")
    end

    def find_cohort_id!(ecf_id:)
      @cohort_by_ecf_id ||= Rails.cache.read(:cohort_by_ecf_id)
      @cohort_by_ecf_id[ecf_id] || raise(ActiveRecord::RecordNotFound, "Couldn't find Cohort")
    end

    def find_application_id!(ecf_id:)
      @application_by_ecf_id ||= Rails.cache.read(:application_by_ecf_id)
      @application_by_ecf_id[ecf_id] || raise(ActiveRecord::RecordNotFound, "Couldn't find Application")
    end

    def find_declaration_id!(ecf_id:)
      @declaration_by_ecf_id ||= Rails.cache.read(:declaration_by_ecf_id)
      @declaration_by_ecf_id[ecf_id] || raise(ActiveRecord::RecordNotFound, "Couldn't find Declaration")
    end

    def find_statement_id!(ecf_id:)
      @statement_by_ecf_id ||= Rails.cache.read(:statement_by_ecf_id)
      @statement_by_ecf_id[ecf_id] || raise(ActiveRecord::RecordNotFound, "Couldn't find Statement")
    end

    def find_course_id!(identifier: nil, ecf_id: nil)
      raise ActiveRecord::RecordNotFound, "Couldn't find Course" unless identifier || ecf_id

      if ecf_id
        @course_by_ecf_id ||= Rails.cache.read(:course_by_ecf_id)
        @course_by_ecf_id[ecf_id] || raise(ActiveRecord::RecordNotFound, "Couldn't find Course")
      else
        @course_by_identifier ||= Rails.cache.read(:course_by_identifier)
        @course_by_identifier[identifier] || raise(ActiveRecord::RecordNotFound, "Couldn't find Course")
      end
    end

    def find_school_id!(urn:)
      @school_by_urn ||= Rails.cache.read(:school_by_urn)
      @school_by_urn[urn] || raise(ActiveRecord::RecordNotFound, "Couldn't find School")
    end

    def find_itt_provider_id!(itt_provider:)
      @itt_provider_by_legal_name_and_operating_name ||= Rails.cache.read(:itt_provider_by_legal_name_and_operating_name)
      @itt_provider_by_legal_name_and_operating_name[itt_provider.downcase] || raise(ActiveRecord::RecordNotFound, "Couldn't find IttProvider")
    end

    def find_private_childcare_provider_id!(provider_urn:)
      @private_childcare_provider_by_urn ||= Rails.cache.read(:private_childcare_provider_by_urn)
      @private_childcare_provider_by_urn[provider_urn] || raise(ActiveRecord::RecordNotFound, "Couldn't find PrivateChildcareProvider")
    end

    def find_user_id!(ecf_id:)
      @user_by_ecf_id ||= Rails.cache.read(:user_by_ecf_id)
      @user_by_ecf_id[ecf_id] || raise(ActiveRecord::RecordNotFound, "Couldn't find User")
    end

    def find_schedule_id!(ecf_id:)
      @schedule_by_ecf_id ||= Rails.cache.read(:schedule_by_ecf_id)
      @schedule_by_ecf_id[ecf_id] || raise(ActiveRecord::RecordNotFound, "Couldn't find Schedule")
    end

    def course_groups_by_schedule_type(ecf_type)
      case ecf_type
      when "Finance::Schedule::NPQLeadership"
        CourseGroup.find_by!(name: :leadership)
      when "Finance::Schedule::NPQSpecialist"
        CourseGroup.find_by!(name: :specialist)
      when "Finance::Schedule::NPQSupport"
        CourseGroup.find_by!(name: :support)
      when "Finance::Schedule::NPQEhco"
        CourseGroup.find_by!(name: :ehco)
      end
    end

  private

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

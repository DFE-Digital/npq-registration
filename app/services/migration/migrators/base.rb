module Migration::Migrators
  class Base
    class << self
      def call(**args)
        new(**args).call
      end

      def model
        name.gsub(/^.*::/, "").underscore.to_sym
      end

      def prepare!
        Migration::DataMigration.create!(model:)
      end
    end

  private

    def model
      self.class.model
    end

    def check_migration_prepared!
      raise Migration::Migrator::MigrationNotPreparedError, "The migration has not been prepared" unless Migration::DataMigration.where(model:).exists?
    end

    def migrate(items, group: false)
      check_migration_prepared!

      data_migration = Migration::DataMigration.find_by(model:)
      data_migration.update!(started_at: data_migration.started_at.presence || Time.zone.now, total_count: data_migration.total_count.to_i + items.count)

      failure_manager = Migration::FailureManager.new(data_migration:)

      items.in_batches.each_record do |item|
        data_migration.increment!(:processed_count)
        begin
          yield(item)
        rescue ActiveRecord::ActiveRecordError => e
          data_migration.increment!(:failure_count)
          failure_manager.record_failure(item, e.message)
        end
      end

      data_migration.update!(completed_at: Time.zone.now) unless group
    end
  end
end

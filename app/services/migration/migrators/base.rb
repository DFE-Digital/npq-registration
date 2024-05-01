module Migration::Migrators
  class Base
    class << self
      def call(**args)
        new(**args).call
      end

      def prepare!
        model = name.gsub(/^.*::/, "").underscore.to_sym

        Migration::DataMigration.create!(model:)
      end
    end

  private

    def migrate(items, model, group: false)
      data_migration = Migration::DataMigration.find_by(model:)
      data_migration.update!(started_at: Time.zone.now, total_count: items.count)

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

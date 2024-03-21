module Migration
  class FailuresRecorder
    class << self
      def record(data_migration:, items:)
        new(data_migration:, items:).record
      end
    end

    def record
      return unless data_migration && items.present?

      record_failure
    end

  private

    attr_reader :data_migration, :items

    def initialize(data_migration:, items:)
      @data_migration = data_migration
      @items = items
    end

    def attributes
      %i[
        id
        ecf_id
      ].freeze
    end

    def extract_attributes
      attributes.index_with { |attr| items.map { |item| item.try(attr).to_s.presence } }.compact
    end

    def to_yaml
      {
        model: data_migration.model,
        items: extract_attributes,
      }.to_yaml
    end

    def record_failure
      Rails.cache.write(data_migration.migration_failures_key, to_yaml, expires_in: 1.month)
    end
  end
end

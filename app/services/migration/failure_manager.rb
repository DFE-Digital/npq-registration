module Migration
  class FailureManager
    class << self
      def combine_failures(data_migrations)
        data_migrations
        .map { |data_migration| new(data_migration:).all_failures_hash }
        .each_with_object({}) { |failure_hash, hash|
          failure_hash.each do |failure_key, failure_values|
            hash[failure_key] ||= []
            hash[failure_key] += failure_values
          end
        }
        .to_yaml
      end
    end

    def record_failure(item, failure_message)
      return if item.blank?

      write_failure(item, failure_message)
    end

    def all_failures
      failures
    end

    def all_failures_hash
      YAML.load(failures.to_s) || {}
    end

  private

    attr_reader :data_migration

    def initialize(data_migration:)
      raise ArgumentError, "Missing data_migration" unless data_migration

      @data_migration = data_migration
    end

    def migration_failure_key
      @migration_failure_key ||= "migration_failure_#{data_migration.model}_#{data_migration.id}"
    end

    def failures
      Rails.cache.read(migration_failure_key)
    end

    def write_failure(item, failure_message)
      failures_hash = all_failures_hash
      failures_hash[failure_message.to_s] ||= []
      failures_hash[failure_message.to_s].push(*item.id)

      failures_yaml = failures_hash.to_yaml
      Rails.cache.write(migration_failure_key.to_s, failures_yaml, expires_in: 1.month)
      failures_yaml
    end
  end
end

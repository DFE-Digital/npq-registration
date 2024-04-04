module Migration
  class FailureManager
    def record_failure(item, failure_message)
      return if item.blank?

      write_failure(item, failure_message)
    end

    def all_failures
      failures
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

    def parsed_failures
      YAML.load(failures.to_s) || {}
    end

    def write_failure(item, failure_message)
      failures_hash = parsed_failures
      failures_hash[failure_message.to_s] ||= []
      failures_hash[failure_message.to_s].push(*item.id)

      failures_yaml = failures_hash.to_yaml
      Rails.cache.write(migration_failure_key.to_s, failures_yaml, expires_in: 1.month)
      failures_yaml
    end
  end
end

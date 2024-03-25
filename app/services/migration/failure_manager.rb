module Migration
  class FailureManager
    def record_failure(item, failure_message)
      return if item.blank?

      write_failure(item, failure_message)
    end

    def all_failures
      read_failures
    end

  private

    attr_reader :data_migration

    def initialize(data_migration:)
      raise ArgumentError, "Missing data_migration" unless data_migration

      @data_migration = data_migration
    end

    def failure(item, failure_message)
      hash = YAML.load(read_failures.to_s) || {}
      hash[failure_message.to_s] ||= []
      hash[failure_message.to_s].push(*item.id)
      hash.to_yaml
    end

    def migration_failure_key
      @migration_failure_key ||= "migration_failure_#{data_migration.model}_#{data_migration.id}"
    end

    def write_failure(item, failure_message)
      failure_yaml = failure(item, failure_message)
      Rails.cache.write(migration_failure_key.to_s, failure_yaml, expires_in: 1.month)
      failure_yaml
    end

    def read_failures
      Rails.cache.read(migration_failure_key)
    end
  end
end

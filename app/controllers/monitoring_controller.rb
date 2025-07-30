class MonitoringController < ActionController::Base
  def healthcheck
    render status:, json: {
      git_commit_sha: ENV["COMMIT_SHA"],
      database: {
        connected: database_connected?,
        migration_version:,
        populated: database_populated?,
      },
      redis: redis_connected?,
    }
  end

  def up
    database_connected? ? head(:ok) : head(:service_unavailable)
  end

private

  def status
    if database_connected? && database_populated? && redis_connected?
      :ok
    else
      :service_unavailable
    end
  end

  def database_connected?
    ApplicationRecord.connection
    ApplicationRecord.connected?
  rescue StandardError
    false
  end

  def database_populated?
    # We use Course as the courses are initialized when the app boots.
    database_connected? && Course.any?
  rescue StandardError
    false
  end

  def migration_version
    ApplicationRecord.connection_pool.migration_context.current_version
  end

  def using_redis?
    Rails.cache.is_a? ActiveSupport::Cache::RedisCacheStore
  end

  def redis_connected?
    return true unless using_redis?

    Rails.cache.redis.with(&:ping) == "PONG"
  rescue Redis::BaseError
    false
  end
end

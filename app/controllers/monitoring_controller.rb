class MonitoringController < ApplicationController
  skip_before_action :set_sentry_user, :initialize_store

  def healthcheck
    render status:, json: {
      git_commit_sha: ENV["COMMIT_SHA"],
      database: {
        connected: database_connected?,
        migration_version:,
        populated: database_populated?,
      },
    }
  end

private

  def status
    if database_connected? && database_populated?
      :ok
    else
      :internal_server_error
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
    ApplicationRecord.connection.migration_context.current_version
  end
end

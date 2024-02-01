class MonitoringController < ActionController::Base
  def healthcheck
    render status:, json: {
      git_commit_sha: ENV["COMMIT_SHA"],
      database: {
        connected: database_connected?,
        populated: database_populated?,
        migration_version:,
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
    ApplicationRecord.connection.select_value("SELECT 1") == 1
  rescue StandardError
    false
  end

  def database_populated?
    [
      ApplicationRecord.connection.select_value("select count(*) from courses;"),
    ].all?(&:positive?)
  rescue StandardError
    false
  end

  def migration_version
    ApplicationRecord.connection.migration_context.current_version
  end
end

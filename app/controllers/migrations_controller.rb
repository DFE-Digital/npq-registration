class MigrationsController < ApplicationController
  before_action :authenticate

  def index
    @most_recent_migration = Migration::Result.most_recent_complete
    @in_progress_migration = Migration::Result.in_progress
  end

  def create
    Migration::Migrator.prepare_for_migration!

    MigrationJob.perform_later

    redirect_to migrations_path
  end

  def download_orphan_report
    result = Migration::Result.find(params[:id])
    yaml = result.cached_orphan_report(params[:key])

    render plain: yaml, content_type: "text/yaml"
  end

private

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      credentials_are_set = [ENV["MIGRATION_USERNAME"], ENV["MIGRATION_PASSWORD"]].all?(&:present?)
      credentials_match = username == ENV["MIGRATION_USERNAME"] && password == ENV["MIGRATION_PASSWORD"]

      credentials_are_set && credentials_match
    end
  end
end

class MigrationsController < ApplicationController
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
end

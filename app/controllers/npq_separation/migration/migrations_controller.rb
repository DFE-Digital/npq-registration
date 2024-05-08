class NpqSeparation::Migration::MigrationsController < ApplicationController
  before_action :require_super_admin

  def index
    @data_migrations = Migration::DataMigration.all
    @in_progress_migration = @data_migrations.present? && !@data_migrations.all?(&:complete?)
    @completed_migration = @data_migrations.present? && @data_migrations.all?(&:complete?)
  end

  def create
    ActiveJob.perform_all_later([MigrationJob.new, MigrationJob.new])

    redirect_to npq_separation_migration_migrations_path
  end

  def download_report
    data_migration = Migration::DataMigration.find(params[:id])
    failures = Migration::FailureManager.new(data_migration:).all_failures

    send_data(failures, filename: "migration_failures_#{data_migration.model}_#{data_migration.id}.yaml", type: "text/yaml", disposition: "attachment")
  end

private

  def require_super_admin
    unless current_admin&.super_admin?
      flash[:negative] = { title: "Unauthorized", text: "Sign in with your admininstrator account" }
      redirect_to sign_in_path
    end
  end
end

class NpqSeparation::Migration::MigrationsController < ApplicationController
  before_action :require_super_admin

  def index
    @data_migrations = Migration::DataMigration.order(model: :asc, worker: :asc).all
    @in_progress_migration = @data_migrations.present? && !@data_migrations.all?(&:complete?)
    @completed_migration = @data_migrations.present? && @data_migrations.all?(&:complete?)
  end

  def create
    Migration::Coordinator.prepare_for_migration
    MigrationJob.perform_later

    redirect_to npq_separation_migration_migrations_path
  end

  def download_report
    data_migrations = Migration::DataMigration.complete.where(model: params[:model])
    failures = data_migrations
      .map { |data_migration| YAML.load(Migration::FailureManager.new(data_migration:).all_failures) }
      .each_with_object({}) { |failure_hash, hash|
        failure_hash.each do |failure_key, failure_values|
          hash[failure_key] ||= []
          hash[failure_key] += failure_values
        end
      }
      .to_yaml

    send_data(failures, filename: "migration_failures_#{params[:model]}_.yaml", type: "text/yaml", disposition: "attachment")
  end

private

  def require_super_admin
    unless current_admin&.super_admin?
      flash[:negative] = { title: "Unauthorized", text: "Sign in with your admininstrator account" }
      redirect_to sign_in_path
    end
  end
end

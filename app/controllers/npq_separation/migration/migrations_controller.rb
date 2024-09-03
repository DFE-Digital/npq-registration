class NpqSeparation::Migration::MigrationsController < SuperAdminController
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
    failures = Migration::FailureManager.combine_failures(data_migrations)

    send_data(failures, filename: "migration_failures_#{params[:model]}.yaml", type: "text/yaml", disposition: "attachment")
  end
end

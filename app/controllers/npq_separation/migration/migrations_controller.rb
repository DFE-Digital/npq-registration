class NpqSeparation::Migration::MigrationsController < SuperAdminController
  def index
    @data_migrations = Migration::DataMigration.all
    @in_progress_migration = @data_migrations.present? && !@data_migrations.all?(&:complete?)
    @completed_migration = @data_migrations.present? && @data_migrations.all?(&:complete?)
  end

  def create
    Migration::Migrator.prepare_for_migration
    MigrationJob.perform_later

    redirect_to npq_separation_migration_migrations_path
  end

  def download_report
    data_migration = Migration::DataMigration.find(params[:id])
    failures = Migration::FailureManager.new(data_migration:).all_failures

    send_data(failures, filename: "migration_failures_#{data_migration.model}_#{data_migration.id}.yaml", type: "text/yaml", disposition: "attachment")
  end
end

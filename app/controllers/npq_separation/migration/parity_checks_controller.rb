class NpqSeparation::Migration::ParityChecksController < SuperAdminController
  def index
    @parity_check_running = Migration::ParityCheck.running?
    @parity_check_started_at = Migration::ParityCheck.started_at
    @parity_check_completed_at = Migration::ParityCheck.completed_at
    @parity_check_completed = Migration::ParityCheck.completed?
  end

  def create
    Migration::ParityCheck.prepare!
    ParityCheckJob.perform_later

    redirect_to npq_separation_migration_parity_checks_path
  end
end

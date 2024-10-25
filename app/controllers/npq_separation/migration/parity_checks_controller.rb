class NpqSeparation::Migration::ParityChecksController < SuperAdminController
  def index
    @parity_check_running = Migration::ParityCheck.running?
    @parity_check_started_at = Migration::ParityCheck.started_at
    @parity_check_completed_at = Migration::ParityCheck.completed_at
    @parity_check_completed = Migration::ParityCheck.completed?
    @response_comparisons_by_lead_provider = Migration::ParityCheck::ResponseComparison.by_lead_provider
    @average_response_times_by_path = Migration::ParityCheck::ResponseComparison.response_times_by_path
  end

  def create
    Migration::ParityCheck.prepare!
    ParityCheckJob.perform_later

    redirect_to npq_separation_migration_parity_checks_path
  end

  def response_comparison
    @comparison = Migration::ParityCheck::ResponseComparison.find(params[:id])
    @matching_comparisons = Migration::ParityCheck::ResponseComparison.matching(@comparison)
    @multiple_results = @matching_comparisons.one? && @comparison.page.nil?
  end
end

class NpqSeparation::Admin::ParticipantOutcomesController < NpqSeparation::AdminController
  def resend
    if participant_outcome.resend_to_qualified_teachers_api!
      flash[:success] = "Rescheduled for delivery to Teacher Services"
    else
      flash[:error] = "Not suitable for resending to Teacher Services"
    end

    redirect_to npq_separation_admin_application_path(participant_outcome.application_id)
  end

private

  def participant_outcome
    @participant_outcome ||= ParticipantOutcome.find(params[:id])
  end
end

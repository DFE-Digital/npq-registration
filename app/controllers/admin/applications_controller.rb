class Admin::ApplicationsController < AdminController
  include Pagy::Backend

  def index
    @pagy, @applications = pagy(scope)
  end

  def show
    @application = Application.includes(:user).find(params[:id])
  end

  def update_approval_status
    @application = Application.find(params[:id])

    new_status = case @application.lead_provider_approval_status
                 when "accepted" then "rejected"
                 when "rejected" then "pending"
                 else "accepted"
                 end

    @application.update!(lead_provider_approval_status: new_status)

    redirect_to accounts_user_registration_path(@application), notice: "Status updated successfully."
  end

  def update_participant_outcome
    @application = Application.find(params[:id])

    new_outcome = case @application.participant_outcome_state
                  when "passed" then "failed"
                  else "passed"
                  end

    @application.update!(participant_outcome_state: new_outcome)

    redirect_to accounts_user_registration_path(@application), notice: "Outcome updated successfully."
  end

private

  def scope
    AdminService::ApplicationsSearch.new(q: params[:q]).call
  end
end

class Admin::ApplicationsController < AdminController
  include Pagy::Backend
  before_action :check_review_env, :find_application, only: %i[update_approval_status update_participant_outcome]

  def index
    @pagy, @applications = pagy(scope)
  end

  def show
    @application = Application.includes(:user).find(params[:id])
  end

  # This method is only written for review apps in order to update the external statuses
  def update_approval_status
    @application.update!(lead_provider_approval_status: @application.get_approval_status)

    redirect_to accounts_user_registration_path(@application), notice: "Status updated successfully."
  end

  # This method is only written for review apps in order to update the external statuses
  def update_participant_outcome
    @application.update!(participant_outcome_state: @application.get_participant_outcome_state)

    redirect_to accounts_user_registration_path(@application), notice: "Outcome updated successfully."
  end

private

  def scope
    AdminService::ApplicationsSearch.new(q: params[:q]).call
  end

  def find_application
    @application = Application.find(params[:id])
  end

  def check_review_env
    redirect_to accounts_user_registration_path(@application), notice: "Access denied. This action is only allowed in review apps." unless Rails.env.review? # rubocop:disable Rails/UnknownEnv
  end
end

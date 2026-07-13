class Accounts::UserRegistrationsController < AccountsController
  before_action :set_application

  def show; end

  def registration_complete; end

private

  def set_application
    @application = current_user.applications.find(params[:id])
  end
end

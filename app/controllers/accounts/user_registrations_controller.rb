class Accounts::UserRegistrationsController < AccountsController
  before_action :set_application

  def show
    # Overrides AccountsController#show, which would redirect back to this page and loop.
  end

private

  def set_application
    @application = current_user.applications.find(params[:id])
  end
end

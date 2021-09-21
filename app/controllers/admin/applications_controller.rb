class Admin::ApplicationsController < AdminController
  def index
    @applications = Application.includes(:user, :course, :lead_provider).all
  end
end

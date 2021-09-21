class Admin::ApplicationsController < AdminController
  include Pagy::Backend

  def index
    @pagy, @applications = pagy(Application.includes(:user, :course, :lead_provider))
  end
end

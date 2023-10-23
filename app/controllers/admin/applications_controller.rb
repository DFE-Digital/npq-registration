class AdminService::ApplicationsController < AdminController
  include Pagy::Backend

  def index
    @pagy, @applications = pagy(scope)
  end

  def show
    @application = Application.includes(:user).find(params[:id])
  end

private

  def scope
    AdminService::ApplicationsSearch.new(q: params[:q]).call
  end
end

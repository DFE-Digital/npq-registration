class Admin::ApplicationsController < AdminController
  include Pagy::Backend

  def index
    @pagy, @applications = pagy(scope)
  end

  def show
    @application = Application.includes(:user).find(params[:id])
  end

private

  def scope
    Services::Admin::ApplicationsSearch.new(q: params[:q]).call
  end
end

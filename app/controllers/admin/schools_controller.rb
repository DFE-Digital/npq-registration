class AdminService::SchoolsController < AdminController
  include Pagy::Backend

  def index
    @pagy, @schools = pagy(scope)
  end

  def show
    @school = School.find(params[:id])
  end

private

  def scope
    AdminService::SchoolsSearch.new(q: params[:q]).call
  end
end

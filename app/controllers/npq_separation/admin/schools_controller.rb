class NpqSeparation::Admin::SchoolsController < NpqSeparation::AdminController
  def index
    @pagy, @schools = pagy(schools_query.schools)
  end

  def show
    @school = schools_query.school(id: params[:id])
  end

private

  def schools_query
    @schools_query ||= Schools::Query.new
  end
end

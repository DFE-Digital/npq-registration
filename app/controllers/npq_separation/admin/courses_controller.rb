class NpqSeparation::Admin::CoursesController < NpqSeparation::AdminController
  def index
    @pagy, @courses = pagy(courses_query.courses)
  end

  def show
    @course = courses_query.course(id: params[:id])
  end

private

  def courses_query
    @courses_query ||= Courses::Query.new
  end
end

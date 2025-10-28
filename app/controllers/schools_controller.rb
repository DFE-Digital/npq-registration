class SchoolsController < PublicPagesController
  def index
    schools = School
      .search_by_name(params[:name])
      .open
      .limit(100)

    render(json: SchoolSerializer.render(schools))
  end
end

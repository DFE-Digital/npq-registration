class InstitutionsController < PublicPagesController
  def index
    schools = School
      .search_by_name(params[:name])
      .open
      .limit(100)

    local_authorities = LocalAuthority
      .search_by_name(params[:name])
      .limit(100)

    render(json: InstitutionSerializer.render(schools + local_authorities))
  end
end

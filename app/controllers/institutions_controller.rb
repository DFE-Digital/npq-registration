class InstitutionsController < PublicPagesController
  def index
    schools = School
      .open
      .search_by_name(params[:name])

    local_authorities = LocalAuthority
      .search_by_name(params[:name])
      .limit(100)

    render(json: InstitutionSerializer.render(schools + local_authorities))
  end
end

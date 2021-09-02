class InstitutionsController < ApplicationController
  def index
    schools = School
      .open
      .search_by_location(params[:location])
      .search_by_name(params[:name])
      .limit(100)

    local_authorities = LocalAuthority
      .search_by_location(params[:location])
      .search_by_name(params[:name])
      .limit(100)

    @institutions = schools + local_authorities
  end
end

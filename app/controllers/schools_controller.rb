class SchoolsController < ApplicationController
  def index
    @schools = School
      .open
      .search_by_location(params[:location])
      .search_by_name(params[:name])
      .limit(100)
  end
end

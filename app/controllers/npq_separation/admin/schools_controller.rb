class NpqSeparation::Admin::SchoolsController < NpqSeparation::AdminController
  def index
    @pagy, @schools = pagy(scope)
    @schools = @schools.map(&:source) unless @schools.is_a?(AdminService::WorkplaceSearch)
  end

private

  def scope
    if params[:usenew].to_s != "0"
      Workplace.includes(:source)
               .order(:name, :source_id)
               .search(params[:q])
    else
      AdminService::WorkplaceSearch.new(q: params[:q])
    end
  end
end

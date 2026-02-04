class NpqSeparation::Admin::SchoolsController < NpqSeparation::AdminController
  def index
    @pagy, @schools = pagy(scope)
    @schools = @schools.map(&:source)
  end

private

  def scope
    Workplace.includes(:source)
             .order(:name, :source_id)
             .search(params[:q])
  end
end

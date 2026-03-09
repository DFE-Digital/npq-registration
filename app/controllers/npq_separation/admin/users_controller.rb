class NpqSeparation::Admin::UsersController < NpqSeparation::AdminController
  MIN_SEARCH_LENGTH = 2

  def index
    search_term = params[:q]
    @valid_search = search_term.present? && search_term.length >= MIN_SEARCH_LENGTH

    @pagy, @users = pagy(scope) if @valid_search
  end

  def show
    @user = User.find(params[:id])
    @applications = @user.applications.includes(:course, :lead_provider, :school).order(:created_at, :id)
  end

private

  def scope
    AdminService::UsersSearch.new(q: params[:q]).call
  end
end

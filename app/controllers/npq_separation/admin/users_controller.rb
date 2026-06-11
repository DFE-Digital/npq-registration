class NpqSeparation::Admin::UsersController < NpqSeparation::AdminController
  MIN_SEARCH_LENGTH = 2

  def index
    @performing_search = params.key?(:q)
    search_term = params[:q]
    @valid_search = search_term.present? && search_term.length >= MIN_SEARCH_LENGTH

    if @performing_search
      @pagy, @users = pagy(scope) if @valid_search
    else
      @users = User.order(created_at: :desc, id: :desc).limit(Pagy::DEFAULT[:limit])
    end
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

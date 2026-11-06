class Admin::UsersController < AdminController
  MIN_SEARCH_LENGTH = 2
  RECENT_USERS_PAGES = 10

  def index
    @performing_search = params.key?(:q)
    search_term = params[:q]
    @valid_search = search_term.present? && search_term.length >= MIN_SEARCH_LENGTH

    if @performing_search
      paginate_search_results if @valid_search
    else
      @pagy, @users = pagy(recent_users_scope)
    end
  end

  def show
    @user = User.find(params[:id])
    @applications = @user.applications.includes(:course, :lead_provider, :school).order(:created_at, :id)
    @legacy_outcomes = @user.legacy_passed_participant_outcomes.for_display
  end

private

  # Users come first, then historic users fill the pages after them
  def paginate_search_results
    users = AdminService::UsersSearch.new(q: params[:q]).call
    historic_users = AdminService::HistoricUsersSearch.new(q: params[:q]).call
    users_count = pagy_get_count(users, {})
    historic_users_count = pagy_get_count(historic_users, {})

    @pagy, @users = pagy(users, count: users_count + historic_users_count)
    @historic_users = historic_users
      .offset([@pagy.offset - users_count, 0].max)
      .limit(@pagy.limit - @users.length)
  end

  def recent_users_scope
    User
      .order(created_at: :desc, id: :desc)
      .limit(Pagy::DEFAULT[:limit] * RECENT_USERS_PAGES)
  end
end

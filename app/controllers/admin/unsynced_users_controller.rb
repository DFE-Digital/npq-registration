class Admin::UnsyncedUsersController < AdminController
  include Pagy::Backend

  def index
    @pagy, @users = pagy(scope)
  end

private

  def scope
    User.unsynced.joins(:applications).order(created_at: :desc)
  end
end

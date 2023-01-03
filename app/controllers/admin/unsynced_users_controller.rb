class Admin::UnsyncedUsersController < AdminController
  include Pagy::Backend

  def index
    @pagy, @users = pagy(scope)
  end

private

  def scope
    User.unsynced
  end
end

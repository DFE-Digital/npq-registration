class ApplicationController < ActionController::Base
  default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder

  before_action :set_sentry_user

private

  def authenticate_user!
    if current_user.null_user?
      redirect_to sign_in_path
    end
  end

  def current_user
    User.find_by(id: session[:user_id]) || NullUser.new
  end

  helper_method :current_user

  def set_sentry_user
    unless current_user.null_user?
      Sentry.set_user(id: current_user.id)
    end
  end
end

class ApplicationController < ActionController::Base
  default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder

  before_action :set_sentry_user
  before_action :set_feature_flag_users
  before_action :initialize_store

private

  def authenticate_user!
    if current_user.null_user?
      redirect_to sign_in_path
    end
  end

  # If the user is logged in then we should retrieve from the logged in user record,
  # otherwise we should generate a new one for assigning to the NullUser record that will
  # later be persisted against a new User record once one is created.
  def feature_flag_id
    return logged_in_user.retrieve_or_persist_feature_flag_id if logged_in_user.present?

    session[:feature_flag_id] ||= SecureRandom.uuid
  end
  helper_method :feature_flag_id

  def current_user
    logged_in_user || NullUser.new(feature_flag_id:)
  end
  helper_method :current_user

  def set_sentry_user
    unless current_user.null_user?
      Sentry.set_user(id: current_user.id)
    end
  end

  # Use current_user instead!
  def logged_in_user
    User.find_by(id: session[:user_id])
  end

  def current_admin
    Admin.find_by(id: session[:admin_id])
  end
  helper_method :current_admin

  def set_feature_flag_users
    users = User.where(email: ClosedRegistrationUser.pluck(:email))
    users.each { |u| Flipper.enable_actor(Feature::REGISTRATION_OPEN, u) }
  end

  def initialize_store
    session["registration_store"] ||= {}
  end
end

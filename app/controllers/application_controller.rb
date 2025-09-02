class ApplicationController < ActionController::Base
  default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder

  around_action :set_time_zone
  before_action :clear_null_user_sessions
  before_action :set_cache_headers
  before_action :authenticate_user!
  before_action :set_sentry_user
  before_action :initialize_store

  include DfE::Analytics::Requests

private

  def authenticate_user!
    raise "ApplicationController should not be used directly. Use a subclass instead."
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
    logged_in_user
  end
  helper_method :current_user

  def set_sentry_user
    Sentry.set_user(id: current_user.id) if current_user
  end

  # Use current_user instead!
  def logged_in_user
    User.find_by(id: session[:user_id]).tap do |public_user|
      PaperTrail.request.whodunnit = "Public User #{public_user.id}" if public_user
    end
  end

  def current_admin
    return unless session[:admin_id]

    if session[:admin_sign_in_at].nil? || session[:admin_sign_in_at] < Time.zone.now.utc.beginning_of_day
      reset_session
      nil
    else
      Admin.find_by(id: session[:admin_id]).tap do |admin_user|
        PaperTrail.request.whodunnit = "Admin #{admin_user.id}" if admin_user
      end
    end
  end
  helper_method :current_admin

  def initialize_store
    session["registration_store"] ||= {}
  end

  def set_cache_headers
    no_store
  end

  def clear_null_user_sessions
    if session.key?(:registration_store) &&
        session[:registration_store][:current_user].is_a?(NullUser)
      reset_session
      redirect_to root_path
    end
  end

  def set_time_zone(&block)
    # Show times in UK local time, ie BST in summer and UTC in winter
    Time.use_zone("London", &block)
  end
end

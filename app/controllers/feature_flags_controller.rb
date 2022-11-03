class FeatureFlagsController < ApplicationController
  before_action :feature_flags_viewer_enabled?

  def show
    if params[:feature_flag].present? && params[:status].present?
      feature_flag = params[:feature_flag]

      if can_flip_feature_flag?(feature_flag)
        status = params[:status]

        case status
        when "on"
          Flipper.enable_actor(feature_flag, current_user)
        when "off"
          Flipper.disable_actor(feature_flag, current_user)
        end
      end

      redirect_to feature_flags_path
    end
  end

private

  def can_flip_feature_flag?(feature_flag)
    Services::Feature.feature_flag_flippable_by_user?(feature_flag)
  end

  def feature_flags_viewer_enabled?
    return if Services::Feature.users_can_flip_own_flags?

    redirect_to root_path
  end
end

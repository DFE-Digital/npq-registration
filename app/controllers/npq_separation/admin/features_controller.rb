class NpqSeparation::Admin::FeaturesController < NpqSeparation::AdminController
  before_action :require_super_admin

  def index
    @features = Feature::FEATURE_FLAG_KEYS
  end

  def show
    @feature = params[:id]
    unless Feature::FEATURE_FLAG_KEYS.include?(@feature)
      redirect_back fallback_location: npq_separation_admin_features_path
    end
  end

  def update
    @feature = params[:id]
    if params[:feature_flag_name] == @feature
      if Flipper.enabled?(@feature)
        Flipper.disable(@feature)
        flash[:success] = "You have turned the #{@feature} feature flag off."
      else
        Flipper.enable(@feature)
        flash[:success] = "You have turned the #{@feature} feature flag on."
      end
    else
      flash[:error] = "There was an error updating the feature flag."
    end
    redirect_to npq_separation_admin_feature_path(@feature)
  end
end

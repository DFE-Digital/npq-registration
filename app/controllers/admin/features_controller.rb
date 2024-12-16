class Admin::FeaturesController < AdminController

    def index
      @features = Feature::FEATURE_FLAG_KEYS
      @features_not_in_use = Flipper::Adapters::ActiveRecord::Feature.where.not(key: Feature::FEATURE_FLAG_KEYS)
    end

    def show
      @feature = params[:id]
      @users = User.with_feature_flag_enabled(@feature)
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
        redirect_back fallback_location: admin_features_path
      else
        flash[:error] = "There was an error updating the feature flag."
        redirect_back fallback_location: admin_features_path
      end
    end
end

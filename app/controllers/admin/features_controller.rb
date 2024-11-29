class Admin::FeaturesController < AdminController

    def index
      # TODO:
      # instead of iterating on the values on the database, lets use
      # Feature::FEATURE_FLAG_KEYS instead.
      # In addition, we want to do 3 checks:
      # 1. If the feature flag is in database. So we can see they are never been used.
      # 2. List all flags in database that are missing in Feature::FEATURE_FLAG_KEYS. So we can delete them.
      # 3. Display amount of users for which feature flag is enabled when its disabled to all others (like closed registration users)
      # Useful code:
      # To find if the feature flag is in database:
      # Flipper::Adapters::ActiveRecord::Feature.where(key: Feature::REGISTRATION_OPEN)
      # To check if the flag is enabled:
      # Flipper.enabled? "some name"
      # Example usage using map:  Feature::FEATURE_FLAG_KEYS.map { |flag| Flipper.enabled? flag }
      @features = Feature::FEATURE_FLAG_KEYS
      @features_not_in_use = Flipper::Adapters::ActiveRecord::Feature.where.not(key: Feature::FEATURE_FLAG_KEYS)
    end

    def show
      @feature = params[:id]
      @users = User.with_feature_flag_enabled(@feature)
    end

    def update
      @feature = params[:id]

      if Flipper.enabled?(@feature)
        Flipper.disable(@feature)
      else
        Flipper.enable(@feature)
      end

      redirect_back fallback_location: admin_features_path
    end

    def destroy
      @feature = params[:id]
      Flipper::Adapters::ActiveRecord::Feature.where(id: @feature).destroy_all

      redirect_back fallback_location: admin_features_path
    end
end

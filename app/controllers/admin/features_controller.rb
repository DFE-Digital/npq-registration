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
      @features = Flipper.features
    end

    def show
      @feature = Flipper[params[:id]]
    end

    def update
      @feature = Flipper[params[:id]]

      if @feature.enabled?
        @feature.disable
      else
        @feature.enable
      end

      redirect_back fallback_location: admin_features_path, notice: "Feature '#{@feature.name}' has been updated."
    end

end

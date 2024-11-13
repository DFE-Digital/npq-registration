class Admin::FeaturesController < AdminController
  
    def index
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
class Admin::FeaturesController < AdminController
  
    def index
      @features = Flipper.features
    end

    def show
      @feature = Flipper[params[:id]]
    end
  
end
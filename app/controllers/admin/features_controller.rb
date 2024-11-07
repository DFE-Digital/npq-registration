class Admin::FeaturesController < AdminController
  
    def index
      @features = Flipper.features
    end

    def show
        @features = Flipper.features
    end
  
  end
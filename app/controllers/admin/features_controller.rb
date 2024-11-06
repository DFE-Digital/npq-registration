class Admin::FeaturesController < AdminController
  
    def index
      @features = Flipper.features
    end
  
  end
module API
  class GuidanceController < ApplicationController
    layout "api_guidance"

    def index; end

    def show
      @page = GuidancePage.new(params[:page])

      render template: @page.template
    end
  end
end

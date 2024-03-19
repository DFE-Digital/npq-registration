module API
  class GuidanceController < ApplicationController
    def index; end

    def show
      @page = GuidancePage.new(params[:page])

      render template: @page.template
    end
  end
end

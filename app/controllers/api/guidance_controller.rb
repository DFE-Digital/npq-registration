module API
  class GuidanceController < ApplicationController
    layout "api_guidance"

    def index
      @page = GuidancePage.index_page
      @release_note = ReleaseNotes.new.latest
    end

    def show
      @page = GuidancePage.new(params[:page])

      render template: @page.template
    end
  end
end

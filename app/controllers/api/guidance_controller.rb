module API
  class GuidanceController < ApplicationController
    layout "api_guidance"

    def index
      @page = Guidance::IndexPage.new
      @latest_release_note = ReleaseNotes.new.latest
    end

    def show
      @page = Guidance::GuidancePage.new(params[:page])

      render template: @page.template
    end
  end
end

module API
  class GuidanceController < ApplicationController
    layout "api_guidance"

    def index; end

    def show
      @page = GuidancePage.new(params[:page])
      @sub_heading_links = @page.sub_headings.map do |heading|
        {
          text: heading,
          href: "##{heading.parameterize}",
        }
      end
      render template: @page.template
    end
  end
end

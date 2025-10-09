# frozen_string_literal: true

module Banners
  class MaintenanceComponent < BaseComponent
    MAINTENANCE_TEXT = "The service provider which hosts DfE Services is having outages and issues. This might mean that you have problems using the API or accessing the service. If you are having issues accessing the service, please try again later."

    def render?
      Feature.maintenance_banner_enabled?
    end

  private

    def title_text
      "Important"
    end

    def text
      MAINTENANCE_TEXT
    end

    def link_text
      "Dismiss"
    end

    def link_href
      maintenance_banner_dismiss_path
    end
  end
end

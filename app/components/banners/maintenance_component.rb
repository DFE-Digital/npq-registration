# frozen_string_literal: true

module Banners
  class MaintenanceComponent < BaseComponent
    MAINTENANCE_TEXT = "This service will be unavailable from 8am to 10am on 25 August 2026."

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

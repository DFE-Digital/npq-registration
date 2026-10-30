# frozen_string_literal: true

module Banners
  class MaintenanceComponent < BaseComponent
    MAINTENANCE_TEXT = "Due to a technical issue registrations are currently unavailable. Please try again later."

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

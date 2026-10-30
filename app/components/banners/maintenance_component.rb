# frozen_string_literal: true

module Banners
  class MaintenanceComponent < BaseComponent
    MAINTENANCE_TEXT = "A technical issue is affecting registration for this DfE service. Please come back after 2 November to use the service. We apologise for the inconvenience."

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

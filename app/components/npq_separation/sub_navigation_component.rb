module NpqSeparation
  class SubNavigationComponent < ViewComponent::Base
    attr_accessor :current_path, :current_section, :structure

    def initialize(current_path, structure:)
      @current_path = current_path
      @structure = structure
    end

    def render?
      structure.present?
    end

    def navigation_link(section)
      link_to(
        section.name,
        section.href,
        class: "x-govuk-sub-navigation__link",
        aria: { current: current?(section.prefix) },
      )
    end

    def navigation_item_classes(section)
      class_names(
        "x-govuk-sub-navigation__section-item",
        "x-govuk-sub-navigation__section-item--current" => current?(section.prefix),
      )
    end

  private

    def current?(prefix)
      # return nil instead of false so Rails' link helper drops the
      # attribute rather than setting "current='false'"
      current_path.start_with?(prefix) || nil
    end
  end
end

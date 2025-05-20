module NpqSeparation
  class SubNavigationComponent < ViewComponent::Base
    attr_accessor :current_path, :current_section, :structure, :heading

    def initialize(current_path, structure:, heading: {})
      @current_path = current_path
      @structure = structure
      @heading = heading
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

    def render_heading
      heading_text  = heading[:text].presence || "Navigation"
      heading_class = class_names("govuk-visually-hidden" => !heading[:visible])

      tag.h2(heading_text, class: heading_class, id: "sub-navigation-heading")
    end

  private

    def current?(prefix)
      # return nil instead of false so Rails' link helper drops the
      # attribute rather than setting "current='false'"
      current_path.start_with?(prefix) || nil
    end
  end
end

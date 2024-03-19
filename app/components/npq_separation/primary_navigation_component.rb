module NpqSeparation
  class PrimaryNavigationComponent < ViewComponent::Base
    attr_accessor :current_path, :sections

    def initialize(current_path, structure:)
      fail unless structure.is_a?(NpqSeparation::NavigationStructure)

      @current_path = current_path
      @sections = mark_current(structure.primary_structure)
    end

    def build_sections
      safe_join(
        sections.map do |section|
          tag.li(
            link_to(section.name, section.href, class: "x-govuk-primary-navigation__link"),
            class: class_names(
              "x-govuk-primary-navigation__item",
              "x-govuk-primary-navigation__item--current" => section == current_section,
            ),
          )
        end,
      )
    end

    def current_section
      sections.find(&:current) || sections.first
    end

  private

    def mark_current(structure)
      structure.each { |node| node.current = current_path.start_with?(node.prefix) }
    end
  end
end

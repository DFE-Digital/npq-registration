module NpqSeparation
  class PrimaryNavigationComponent < ViewComponent::Base
    attr_accessor :current_path, :sections

    def initialize(current_path, structure:, default_to_first_section: true)
      fail unless structure.is_a?(NpqSeparation::NavigationStructure)

      @default_to_first_section = default_to_first_section
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
      sections.find(&:current) || default_section
    end

    def default_section
      return nil unless default_to_first_section

      sections.first
    end

  private

    attr_reader :default_to_first_section

    def mark_current(structure)
      structure.each { |node| node.current = current_path.start_with?(node.prefix) }
    end
  end
end

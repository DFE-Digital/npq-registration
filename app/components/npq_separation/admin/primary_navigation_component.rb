module NpqSeparation
  module Admin
    class PrimaryNavigationComponent < ViewComponent::Base
      attr_accessor :current_path, :sections

      def initialize(current_path, structure:)
        @current_path = current_path
        @sections = mark_current(structure)
      end

      def build_sections
        safe_join(
          sections.map do |section|
            tag.li(
              link_to(section.name, section.path, class: "x-govuk-primary-navigation__link"),
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
        structure.sections.each { |node| node.current = current_path.start_with?(node.prefix) }
      end

      class PrimaryNavigationStructure
        include Rails.application.routes.url_helpers

        Node = Struct.new(:name, :path, :prefix, :current, keyword_init: true)

        def sections = fail(NotImplementedError)
      end

      class AdminNavigationStructure < PrimaryNavigationStructure
        def sections
          [
            Node.new(
              name: "Dashboard",
              path: npq_separation_admin_path,
              prefix: "/npq-separation/admin/dashboard",
            ),
            Node.new(
              name: "Applications",
              path: npq_separation_admin_applications_path,
              prefix: "/npq-separation/admin/applications",
            ),
            Node.new(
              name: "Finance",
              path: npq_separation_admin_finance_statements_path,
              prefix: "/npq-separation/admin/finance",
            ),
            Node.new(
              name: "Schools",
              path: "#",
              prefix: "/npq-separation/admin/schools",
            ),
            Node.new(
              name: "Lead providers",
              path: "#",
              prefix: "/npq-separation/admin/lead_providers",
            ),
            Node.new(
              name: "Settings",
              path: "#",
              prefix: "/npq-separation/admin/settings",
            ),
          ]
        end
      end

      class APIGuidanceNavigation < PrimaryNavigationStructure
        def sections
          []
        end
      end
    end
  end
end

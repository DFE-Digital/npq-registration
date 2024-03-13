module NpqSeparation
  module Admin
    class PrimaryNavigationComponent < ViewComponent::Base
      attr_accessor :current_path, :sections

      def initialize(current_path, structure:)
        @current_path = current_path
        @sections = set_current(structure)
      end

      def nodes
        safe_join(
          sections.map do |node|
            tag.li(
              link_to(node.name, node.path, class: "x-govuk-primary-navigation__link"),
              class: class_names(
                "x-govuk-primary-navigation__item",
                "x-govuk-primary-navigation__item--current" => current_path.start_with?(node.prefix),
              ),
            )
          end,
        )
      end

      def current_section
        sections.find(&:current)
      end

      def set_current(structure)
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
              path: npq_separation_admin_dashboards_summary_path,
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

module NpqSeparation
  module Admin
    class SecondaryNavigationComponent < ViewComponent::Base
      attr_accessor :current_path, :current_section, :structure

      def initialize(current_path, current_section:, structure:)
        @current_path = current_path
        @current_section = current_section
        @structure = structure
      end

      def sections
        structure.sections.fetch(current_section)
      end

      def render?
        current_section.present?
      end

      def secondary_navigation_link(section)
        link_to(
          section.name,
          section.path,
          class: "x-govuk-sub-navigation__link",
          aria: { current: current?(section.prefix) },
        )
      end

      def secondary_navigation_item_link(node)
        link_to(
          node.name,
          node.path,
          class: "x-govuk-sub-navigation__link",
          aria: { current: current?(node.prefix) },
        )
      end

    private

      def current?(prefix)
        # return nil instead of false so Rails' link helper drops the
        # attribute rather than setting "current='false'"
        current_path.start_with?(prefix) || nil
      end

      class SecondaryNavigationStructure
        include Rails.application.routes.url_helpers

        Section = Struct.new(:name, :path, :prefix, :nodes, keyword_init: true)
        Node = Struct.new(:name, :path, :prefix, keyword_init: true)

        def sections = fail(NotImplementedError)
      end

      class AdminNavigationStructure < SecondaryNavigationStructure
        def sections
          {
            "Dashboard" => [
              Section.new(
                name: "Summary",
                path: npq_separation_admin_dashboards_summary_path,
                prefix: "/npq-separation/admin/dashboard",
                nodes: [
                  Node.new(name: "Dashboard 1", path: "#", prefix: "/npq-separation/admin/dashboards/one"),
                  Node.new(name: "Dashboard 2", path: "#", prefix: "/npq-separation/admin/dashboards/two"),
                ],
              ),
            ],
            "Applications" => [],
            "Finance" => [
              Section.new(
                name: "Statements",
                path: npq_separation_admin_finance_statements_path,
                prefix: "/npq-separation/admin/finance/statements",
                nodes: [
                  Node.new(name: "Unpaid statements", path: npq_separation_admin_finance_unpaid_index_path, prefix: "/npq-separation/admin/finance/statements/unpaid"),
                  Node.new(name: "Paid statements", path: npq_separation_admin_finance_paid_index_path, prefix: "/npq-separation/admin/finance/statements/paid"),
                ],
              ),
              Section.new(name: "Declarations", path: "#", prefix: "/npq-separation/admin/finance/declarations"),
              Section.new(name: "Contracts", path: "#", prefix: "/npq-separation/admin/finance/contracts"),
            ],
            "Schools" => [],
            "Lead providers" => [],
            "Settings" => [],
            "Dashboards" => [],
          }
        end
      end

      class APIGuidanceStructure < SecondaryNavigationStructure
        def sections
          {}
        end
      end
    end
  end
end

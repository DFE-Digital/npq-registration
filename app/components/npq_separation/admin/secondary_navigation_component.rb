module NpqSeparation
  module Admin
    class SecondaryNavigationComponent < ViewComponent::Base
      attr_accessor :current_path

      Section = Struct.new(:name, :path, :prefix, :nodes, keyword_init: true)
      Node = Struct.new(:name, :path, :prefix, keyword_init: true)

      def initialize(current_path)
        @current_path = current_path
      end

      def sections
        structure.fetch(current_section)
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

      def current_section
        all_sections = [
          Node.new(name: "Applications", prefix: "/npq-separation/admin/applications"),
          Node.new(name: "Finance", prefix: "/npq-separation/admin/finance"),
          Node.new(name: "Schools", prefix: "/npq-separation/admin/schools"),
          Node.new(name: "Lead providers", prefix: "/npq-separation/admin/lead-providers"),
          Node.new(name: "Settings", prefix: "/npq-separation/admin/settings"),

          # Dashboard is a special case as it's the admin 'landing page' so has the
          # '/admin' path as well as '/admin/dashboards/summary', so we'll match it
          # last
          Node.new(name: "Dashboard", prefix: %r{/npq-separation/(admin|admin/dashboard)}),
        ]

        matching_section = all_sections.find { |ps| current_path.start_with?(ps.prefix) }

        if matching_section.nil?
          Rails.logger.error("No matching admin section for '#{current_path}'")

          return
        end

        matching_section.name
      end

      def structure
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
  end
end

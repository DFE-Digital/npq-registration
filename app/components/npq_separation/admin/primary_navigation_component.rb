module NpqSeparation
  module Admin
    class PrimaryNavigationComponent < ViewComponent::Base
      attr_accessor :current_path

      Node = Struct.new(:name, :path, :prefix, keyword_init: true)

      def initialize(current_path)
        @current_path = current_path
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

    private

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
  end
end

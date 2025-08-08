module NpqSeparation
  module NavigationStructures
    class AdminNavigationStructure < NpqSeparation::NavigationStructure
      include Rails.application.routes.url_helpers
      include AdminHelper

      def initialize(current_admin)
        @current_admin = current_admin
      end

    private

      # Returns a hash where the keys are primary nodes and the values are
      # sub nodes nested with the 'nodes: key'
      def structure
        admin_nodes.merge(super_admin_nodes)
      end

      def super_admin_nodes
        return {} unless @current_admin.super_admin?

        {
          Node.new(
            name: "Feature flags",
            href: npq_separation_admin_features_path,
            prefix: "/npq-separation/admin/features",
          ) => [],

          Node.new(
            name: "Admins",
            href: npq_separation_admin_admins_path,
            prefix: "/npq-separation/admin/admins",
          ) => [],
        }
      end

      def admin_nodes
        {
          Node.new(
            name: "Dashboards",
            href: npq_separation_admin_path,
            prefix: "/npq-separation/admin/dashboard",
          ) => dashboard_nodes,
          Node.new(
            name: "Applications",
            href: npq_separation_admin_applications_path,
            prefix: "/npq-separation/admin/applications",
          ) => application_nodes,
          Node.new(
            name: "Cohorts",
            href: npq_separation_admin_cohorts_path,
            prefix: "/npq-separation/admin/cohorts",
          ) => [],
          Node.new(
            name: "Courses",
            href: npq_separation_admin_courses_path,
            prefix: "/npq-separation/admin/courses",
          ) => [],
          Node.new(
            name: "Users",
            href: npq_separation_admin_users_path,
            prefix: "/npq-separation/admin/users",
          ) => [],
          Node.new(
            name: "Finance",
            href: npq_separation_admin_finance_statements_path,
            prefix: "/npq-separation/admin/finance",
          ) => [],
          Node.new(
            name: "Workplaces",
            href: npq_separation_admin_schools_path,
            prefix: "/npq-separation/admin/schools",
          ) => [],
          Node.new(
            name: "Providers",
            href: npq_separation_admin_lead_providers_path,
            prefix: "/npq-separation/admin/providers",
          ) => [],
          Node.new(
            name: "Delivery partners",
            href: npq_separation_admin_delivery_partners_path,
            prefix: "/npq-separation/admin/delivery-partners",
          ) => [],
          Node.new(
            name: "Bulk changes",
            href: npq_separation_admin_bulk_operations_path,
            prefix: "/npq-separation/admin/bulk-changes",
          ) => [],
          Node.new(
            name: "Webhook messages",
            href: npq_separation_admin_webhook_messages_path,
            prefix: "/npq-separation/admin/webhook-messages",
          ) => [],
          Node.new(
            name: "Registration closed",
            href: npq_separation_admin_registration_closed_index_path,
            prefix: "/npq-separation/admin/registration-closed",
          ) => [],
        }
      end

      def application_nodes
        [
          Node.new(
            name: "All applications",
            href: npq_separation_admin_applications_path,
            prefix: /\/npq-separation\/admin\/applications(?!\/reviews)$/,
          ),
          Node.new(
            name: "In review",
            href: npq_separation_admin_application_reviews_path,
            prefix: /\/npq-separation\/admin\/applications\/reviews$/,
          ),
        ]
      end

      def dashboard_nodes
        [
          Node.new(
            name: "Courses dashboard",
            href: npq_separation_admin_dashboard_path("courses-dashboard"),
            prefix: "/npq-separation/admin/dashboards/courses-dashboard",
          ),
          Node.new(
            name: "Providers dashboard",
            href: npq_separation_admin_dashboard_path("providers-dashboard"),
            prefix: "/npq-separation/admin/dashboards/providers-dashboard",
          ),
        ]
      end
    end
  end
end

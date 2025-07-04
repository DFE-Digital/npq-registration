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
            name: "Dashboard",
            href: npq_separation_admin_path,
            prefix: "/npq-separation/admin/dashboard",
          ) => [],
          Node.new(
            name: "Applications",
            href: npq_separation_admin_applications_path,
            prefix: "/npq-separation/admin/applications",
          ) => application_nodes,
          Node.new(
            name: "Cohorts",
            href: npq_separation_admin_cohorts_path,
            prefix: "/npq-separation/admin/cohorts",
          ) => cohort_nodes,
          Node.new(
            name: "Courses",
            href: npq_separation_admin_courses_path,
            prefix: "/npq-separation/admin/courses",
          ) => [],
          Node.new(
            name: "Users",
            href: npq_separation_admin_users_path,
            prefix: "/npq-separation/admin/users",
          ) => application_nodes,
          Node.new(
            name: "Finance",
            href: npq_separation_admin_finance_statements_path,
            prefix: "/npq-separation/admin/finance",
          ) => [
            Node.new(
              name: "Statements",
              href: npq_separation_admin_finance_statements_path,
              prefix: "/npq-separation/admin/finance/statements",
              nodes: [],
            ),
            Node.new(name: "Cohorts", href: "/npq-separation/admin/cohorts", prefix: "/npq-separation/admin/cohorts"),
          ],
          Node.new(
            name: "Workplaces",
            href: npq_separation_admin_schools_path,
            prefix: "/npq-separation/admin/schools",
          ) => [],
          Node.new(
            name: "Course providers",
            href: npq_separation_admin_lead_providers_path,
            prefix: "/npq-separation/admin/lead-providers",
          ) => [],
          Node.new(
            name: "Bulk operations",
            href: npq_separation_admin_bulk_operations_path,
            prefix: "/npq-separation/admin/bulk-operations",
          ) => [],
          Node.new(
            name: "Delivery partners",
            href: npq_separation_admin_delivery_partners_path,
            prefix: "/npq-separation/admin/delivery-partners",
          ) => [],
          Node.new(
            name: "Settings",
            href: npq_separation_admin_settings_webhook_messages_path,
            prefix: "/npq-separation/admin/settings",
          ) => settings_nodes,
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

      def cohort_nodes
        [
          Node.new(
            name: "All cohorts",
            href: npq_separation_admin_cohorts_path,
            prefix: /\/npq-separation\/admin\/cohorts$/,
          ),
        ] + Cohort.order(start_year: :desc).map do |cohort|
          Node.new(
            name: "Cohort #{format_cohort(cohort)}",
            href: npq_separation_admin_cohort_path(cohort),
            prefix: "/npq-separation/admin/cohorts/#{cohort.id}",
          )
        end
      end

      def settings_nodes
        [
          Node.new(
            name: "Webhook messages",
            href: npq_separation_admin_settings_webhook_messages_path,
            prefix: "/npq-separation/admin/settings/webhook-messages",
          ),
        ]
      end
    end
  end
end

module NpqSeparation
  module NavigationStructures
    class AdminNavigationStructure < NpqSeparation::NavigationStructure
      include Rails.application.routes.url_helpers

    private

      # Returns a hash where the keys are primary nodes and the values are
      # sub nodes nested with the 'nodes: key'
      def structure
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
          ) => [],
          Node.new(
            name: "Courses",
            href: npq_separation_admin_courses_path,
            prefix: "/npq-separation/admin/courses",
          ) => [],
          Node.new(
            name: "Participants",
            href: npq_separation_admin_users_path,
            prefix: "/npq-separation/admin/users",
          ) => [],
          Node.new(
            name: "Finance",
            href: npq_separation_admin_finance_statements_path,
            prefix: "/npq-separation/admin/finance",
          ) => [
            Node.new(
              name: "Statements",
              href: npq_separation_admin_finance_statements_path,
              prefix: "/npq-separation/admin/finance/statements",
              nodes: [
                Node.new(name: "Unpaid statements", href: npq_separation_admin_finance_unpaid_index_path, prefix: "/npq-separation/admin/finance/statements/unpaid"),
                Node.new(name: "Paid statements", href: npq_separation_admin_finance_paid_index_path, prefix: "/npq-separation/admin/finance/statements/paid"),
              ],
            ),
            Node.new(name: "Declarations", href: "#", prefix: "/npq-separation/admin/finance/declarations"),
            Node.new(name: "Contracts", href: "#", prefix: "/npq-separation/admin/finance/contracts"),
          ],
          Node.new(
            name: "Schools",
            href: npq_separation_admin_schools_path,
            prefix: "/npq-separation/admin/schools",
          ) => [],
          Node.new(
            name: "Lead providers",
            href: npq_separation_admin_lead_providers_path,
            prefix: "/npq-separation/admin/lead_providers",
          ) => [],
          Node.new(
            name: "Bulk operations",
            href: npq_separation_admin_bulk_operations_path,
            prefix: "/npq-separation/admin/bulk_operations",
          ) => [],
          Node.new(
            name: "Settings",
            href: "#",
            prefix: "/npq-separation/admin/settings",
          ) => [],
        }
      end
    end
  end
end

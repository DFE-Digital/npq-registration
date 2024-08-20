require "rails_helper"

RSpec.describe Migration::Migrators::Course do
  it_behaves_like "a migrator", :course, [] do
    def create_ecf_resource
      create(:ecf_migration_npq_course)
    end

    def create_npq_resource(ecf_resource)
      create(:course, ecf_id: ecf_resource.id)
    end

    def setup_failure_state
      # ECF course with no identifier
      create(:ecf_migration_npq_course, identifier: "")
    end
  end
end

require "rails_helper"

RSpec.describe Migration::Migrators::LeadProvider do
  it_behaves_like "a migrator", :lead_provider, [] do
    def create_ecf_resource
      create(:ecf_migration_npq_lead_provider)
    end

    def create_npq_resource(ecf_resource)
      create(:lead_provider, ecf_id: ecf_resource.id)
    end

    def setup_failure_state
      # LeadProvider in ECF with no match in NPQ reg.
      create(:ecf_migration_npq_lead_provider)
    end
  end
end

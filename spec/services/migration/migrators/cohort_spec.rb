require "rails_helper"

RSpec.describe Migration::Migrators::Cohort do
  it_behaves_like "a migrator", :cohort, [] do
    def create_ecf_resource
      create(:ecf_migration_cohort, :with_sequential_start_year)
    end

    def create_npq_resource(ecf_resource)
      create(:cohort, start_year: ecf_resource.start_year)
    end

    def setup_failure_state
      # ECF cohort with no registration start date
      create(:ecf_migration_cohort, :with_sequential_start_year, registration_start_date: nil)
    end
  end
end

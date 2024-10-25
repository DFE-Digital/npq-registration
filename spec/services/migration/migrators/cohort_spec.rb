require "rails_helper"

RSpec.describe Migration::Migrators::Cohort do
  it_behaves_like "a migrator", :cohort, [] do
    def create_ecf_resource
      travel_to(rand(100).hours.ago) do
        create(:ecf_migration_cohort, :with_sequential_start_year)
      end
    end

    def create_npq_resource(ecf_resource)
      create(:cohort, ecf_id: ecf_resource.id, start_year: ecf_resource.start_year)
    end

    def setup_failure_state
      # ECF cohort with no registration start date
      create(:ecf_migration_cohort, :with_sequential_start_year, registration_start_date: nil)
    end

    describe "#call" do
      it "sets the created Cohort attributes correctly" do
        instance.call
        cohort = Cohort.find_by!(ecf_id: ecf_resource1.id)
        expect(cohort.attributes).to include(ecf_resource1.attributes.slice("start_year", "registration_start_date"))
        expect(cohort.created_at.to_s).to eq(ecf_resource1.created_at.to_s)
        expect(cohort.updated_at.to_s).to eq(ecf_resource1.updated_at.to_s)
      end

      context "when the npq_registration_start_date is set on the ECF cohort" do
        it "favours this over the registration_start_date" do
          ecf_cohort = create(:ecf_migration_cohort, :with_sequential_start_year, :with_npq_registration_start_date)
          instance.call
          cohort = Cohort.find_by!(ecf_id: ecf_cohort.id)
          expect(cohort.registration_start_date).to eq(ecf_cohort.npq_registration_start_date)
        end
      end
    end
  end
end

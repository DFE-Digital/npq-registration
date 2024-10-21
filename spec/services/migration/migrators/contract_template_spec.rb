require "rails_helper"

RSpec.describe Migration::Migrators::ContractTemplate do
  it_behaves_like "a migrator", :contract_template, [] do
    def create_ecf_resource
      cohort = create(:ecf_migration_cohort)
      npq_lead_provider = create(:ecf_migration_npq_lead_provider)
      course = create(:ecf_migration_npq_course)
      version = rand(1..9)

      create(
        :ecf_migration_statement,
        cpd_lead_provider: npq_lead_provider.cpd_lead_provider,
        cohort:,
        contract_version: "0.0.#{version}",
      )
      create(
        :ecf_migration_npq_contract,
        npq_lead_provider:,
        cohort:,
        course_identifier: course.identifier,
        version: "0.0.#{version}",
        created_at: rand(1..100).days.ago,
        updated_at: rand(1..100).days.ago,
      )
    end

    def create_npq_resource(ecf_resource); end

    def setup_failure_state
      # NPQ contract in ECF with a negative recruitment_target
      create(
        :ecf_migration_npq_contract,
        recruitment_target: -300,
      )
    end

    describe "#call" do
      it "sets the created ContractTemplate attributes correctly" do
        instance.call

        contract_template = ContractTemplate.find_by!(ecf_id: ecf_resource1.id)
        attrs = ecf_resource1.attributes.slice(*described_class::SHARED_ATTRIBUTES)
        expect(contract_template).to have_attributes(attrs)
      end
    end
  end
end

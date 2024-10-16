require "rails_helper"

RSpec.describe Migration::Migrators::Contract do
  it_behaves_like "a migrator", :contract, %i[course statement] do
    let(:records_per_worker_divider) { 2 }

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

    def create_npq_resource(ecf_resource)
      lead_provider = create(:lead_provider, ecf_id: ecf_resource.npq_lead_provider.id)
      cohort = create(:cohort, start_year: ecf_resource.cohort.start_year)
      course = create(:course, identifier: ecf_resource.course_identifier)
      ecf_statement = Migration::Ecf::Finance::Statement.where(cpd_lead_provider: ecf_resource.npq_lead_provider.cpd_lead_provider).first!
      statement = create(
        :statement,
        ecf_id: ecf_statement.id,
        lead_provider:,
        cohort:,
      )
      contract_template = create(
        :contract_template,
        ecf_id: ecf_resource.id,
      )
      create(
        :contract,
        statement:,
        course:,
        contract_template:,
      )
    end

    def setup_failure_state
      # NPQ Contract with statement in ECF but statement has not been migrated
      cohort = create(:ecf_migration_cohort)
      npq_lead_provider = create(:ecf_migration_npq_lead_provider)

      create(
        :ecf_migration_statement,
        cpd_lead_provider: npq_lead_provider.cpd_lead_provider,
        cohort:,
        contract_version: "0.0.1",
      )

      create(
        :ecf_migration_npq_contract,
        npq_lead_provider:,
        cohort:,
        version: "0.0.1",
      )
    end

    describe "#call" do
      it "sets the created Contract and ContractTemplate attributes correctly" do
        instance.call

        ecf_statements = Migration::Ecf::Finance::Statement.where(cpd_lead_provider: ecf_resource1.npq_lead_provider.cpd_lead_provider)
        expect(ecf_statements.count).to eq(1)

        lead_provider = LeadProvider.find_by!(ecf_id: ecf_resource1.npq_lead_provider.id)
        statements = Statement.where(lead_provider:)
        expect(statements.count).to eq(1)

        statement = statements.first
        expect(statement.cohort.start_year).to eq(ecf_resource1.cohort.start_year)

        contracts = statement.contracts
        expect(contracts.count).to eq(1)

        contract = statement.contracts.first
        expect(contract.course.identifier).to eq(ecf_resource1.course_identifier)

        contract_template = contract.contract_template
        expect(contract_template.ecf_id).to eq(ecf_resource1.id)

        attrs = ecf_resource1.attributes.slice(*described_class::SHARED_ATTRIBUTES)
        expect(contract_template).to have_attributes(attrs)

        expect(Contract.where(contract_template:).count).to eq(1)
      end
    end
  end
end

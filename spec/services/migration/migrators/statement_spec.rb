require "rails_helper"

RSpec.describe Migration::Migrators::Statement do
  it_behaves_like "a migrator", :statement, %i[cohort lead_provider] do
    def create_ecf_resource
      create(:ecf_migration_statement, name: "March 2023")
    end

    def create_npq_resource(ecf_resource)
      lead_provider = create(:lead_provider, ecf_id: ecf_resource.npq_lead_provider.id)
      cohort = create(:cohort, start_year: ecf_resource.cohort.start_year)
      create(:statement, lead_provider:, cohort:)
    end

    def setup_failure_state
      # Statement in ECF with no output_fee.
      ecf_statement = create(:ecf_migration_statement, output_fee: nil)
      create(:lead_provider, ecf_id: ecf_statement.npq_lead_provider.id)
    end

    describe "#call" do
      it "sets the created Statement attributes correctly" do
        instance.call
        statement = Statement.find_by(ecf_id: ecf_resource1.id)
        expect(statement).to have_attributes(ecf_resource1.attributes.slice(:deadline_date, :payment_date, :output_fee, :marked_as_paid_at, :reconcile_amount))
        expect(statement.month).to eq(3)
        expect(statement.year).to eq(2023)
        expect(statement.cohort.start_year).to eq(ecf_resource1.cohort.start_year)
        expect(statement.lead_provider.ecf_id).to eq(ecf_resource1.cpd_lead_provider.npq_lead_provider.id)
        expect(statement.state).to eq("open")
      end
    end
  end
end

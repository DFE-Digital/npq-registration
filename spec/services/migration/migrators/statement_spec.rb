require "rails_helper"

RSpec.describe Migration::Migrators::Statement do
  let(:instance) { described_class.new }

  subject { instance.call }

  describe "#call" do
    before do
      ecf_statement1 = create(:ecf_migration_statement, name: "July 2026")
      ecf_statement2 = create(:ecf_migration_statement, name: "January 2030")

      lead_provider1 = create(:lead_provider, ecf_id: ecf_statement1.npq_lead_provider.id)
      lead_provider2 = create(:lead_provider, ecf_id: ecf_statement2.npq_lead_provider.id)

      cohort1 = create(:cohort, start_year: ecf_statement1.cohort.start_year)
      cohort2 = create(:cohort, start_year: ecf_statement2.cohort.start_year)

      create(:statement, month: 7, year: 2026, lead_provider: lead_provider1, cohort: cohort1)
      create(:statement, month: 1, year: 2030, lead_provider: lead_provider2, cohort: cohort2)

      create(:data_migration, model: :statement)
    end

    it "migrates the statements" do
      subject

      expect(Migration::DataMigration.find_by(model: :statement).processed_count).to eq(2)
    end

    context "when a statement is not correctly created" do
      let!(:ecf_migration_statement) { create(:ecf_migration_statement, output_fee: nil) }

      before { create(:lead_provider, ecf_id: ecf_migration_statement.npq_lead_provider.id) }

      it "increments the failure count" do
        subject

        expect(Migration::DataMigration.find_by(model: :statement).processed_count).to eq(3)
        expect(Migration::DataMigration.find_by(model: :statement).failure_count).to eq(1)
      end

      it "calls FailureManager with correct params" do
        expect_any_instance_of(Migration::FailureManager).to receive(:record_failure).with(ecf_migration_statement, "Validation failed: Output fee Choose yes or no for output fee").and_call_original

        subject
      end
    end
  end
end

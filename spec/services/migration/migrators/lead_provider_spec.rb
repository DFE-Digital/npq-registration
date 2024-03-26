require "rails_helper"

RSpec.describe Migration::Migrators::LeadProvider do
  let(:instance) { described_class.new }

  subject { instance.call }

  describe "#call" do
    before do
      ecf_npq_lead_provider1 = create(:ecf_migration_npq_lead_provider)
      ecf_npq_lead_provider2 = create(:ecf_migration_npq_lead_provider)

      create(:lead_provider, ecf_id: ecf_npq_lead_provider1.id)
      create(:lead_provider, ecf_id: ecf_npq_lead_provider2.id)

      create(:data_migration, model: :lead_provider)
    end

    it "migrates the lead providers" do
      subject

      expect(Migration::DataMigration.find_by(model: :lead_provider).processed_count).to eq(2)
    end

    context "when a lead provider cannot be found" do
      let!(:ecf_migration_npq_lead_provider) { create(:ecf_migration_npq_lead_provider) }

      it "increments the failure count" do
        subject

        expect(Migration::DataMigration.find_by(model: :lead_provider).processed_count).to eq(3)
        expect(Migration::DataMigration.find_by(model: :lead_provider).failure_count).to eq(1)
      end

      it "calls FailureManager with correct params" do
        expect_any_instance_of(Migration::FailureManager).to receive(:record_failure).with(ecf_migration_npq_lead_provider, "Couldn't find LeadProvider with [WHERE \"lead_providers\".\"ecf_id\" = $1]").and_call_original

        subject
      end
    end
  end
end

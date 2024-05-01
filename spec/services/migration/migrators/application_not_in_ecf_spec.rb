require "rails_helper"

RSpec.describe Migration::Migrators::ApplicationNotInEcf do
  let(:instance) { described_class.new }

  subject { instance.call }

  describe "#call" do
    let!(:ecf_npq_application1) { create(:ecf_migration_npq_application) }
    let!(:ecf_npq_application2) { create(:ecf_migration_npq_application) }

    before do
      create(:application, ecf_id: ecf_npq_application1.id)
      create(:application, ecf_id: ecf_npq_application2.id)

      create(:data_migration, model: :application_not_in_ecf)
    end

    context "when an application exists in both NPQ registration and ECF" do
      it "migrates the applications" do
        subject

        expect(Migration::DataMigration.find_by(model: :application_not_in_ecf).processed_count).to eq(2)
        expect(Migration::DataMigration.find_by(model: :application_not_in_ecf).failure_count).to eq(0)
      end
    end

    context "when an application exists in NPQ registration but cannot be matched to an application in ECF" do
      let!(:npq_application) { create(:application) }

      it "increments the failure count" do
        subject

        expect(Migration::DataMigration.find_by(model: :application_not_in_ecf).processed_count).to eq(3)
        expect(Migration::DataMigration.find_by(model: :application_not_in_ecf).failure_count).to eq(1)
      end

      it "calls FailureManager with correct params" do
        expect_any_instance_of(Migration::FailureManager).to receive(:record_failure).with(npq_application, "Couldn't find Migration::Ecf::NpqApplication with [WHERE \"npq_applications\".\"id\" = $1]").and_call_original

        subject
      end
    end
  end
end

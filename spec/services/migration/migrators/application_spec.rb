require "rails_helper"

RSpec.describe Migration::Migrators::Application do
  let(:instance) { described_class.new }

  subject { instance.call }

  describe "#call" do
    let(:ecf_npq_application1) { create(:ecf_migration_npq_application) }
    let(:ecf_npq_application2) { create(:ecf_migration_npq_application) }

    before do
      create(:application, ecf_id: ecf_npq_application1.id)
      create(:application, ecf_id: ecf_npq_application2.id)

      create(:data_migration, model: :application)
    end

    context "when all attributes values of interest matches" do
      before do
        allow_any_instance_of(Migration::Ecf::NpqApplication).to receive(:attributes).and_return({})
        allow_any_instance_of(Application).to receive(:attributes).and_return({})
      end

      it "migrates the applications" do
        subject

        expect(Migration::DataMigration.find_by(model: :application).processed_count).to eq(2)
        expect(Migration::DataMigration.find_by(model: :application).failure_count).to eq(0)
      end
    end

    context "when any attributes values do not match" do
      it "increments the failure count" do
        subject

        expect(Migration::DataMigration.find_by(model: :application).processed_count).to eq(2)
        expect(Migration::DataMigration.find_by(model: :application).failure_count).to eq(2)
      end

      it "calls FailureManager with correct params" do
        expect_any_instance_of(Migration::FailureManager).to receive(:record_failure).with(ecf_npq_application1, "Validation failed: There are some discrepancies in one or more attributes values").and_call_original
        expect_any_instance_of(Migration::FailureManager).to receive(:record_failure).with(ecf_npq_application2, "Validation failed: There are some discrepancies in one or more attributes values").and_call_original

        subject
      end
    end

    context "when a application is not correctly created" do
      let!(:ecf_migration_npq_application) { create(:ecf_migration_npq_application) }

      before do
        allow_any_instance_of(Migration::Ecf::NpqApplication).to receive(:attributes).and_return({})
        allow_any_instance_of(Application).to receive(:attributes).and_return({})
      end

      it "increments the failure count" do
        subject

        expect(Migration::DataMigration.find_by(model: :application).processed_count).to eq(3)
        expect(Migration::DataMigration.find_by(model: :application).failure_count).to eq(1)
      end

      it "calls FailureManager with correct params" do
        expect_any_instance_of(Migration::FailureManager).to receive(:record_failure).with(ecf_migration_npq_application, "Couldn't find Application with [WHERE \"applications\".\"ecf_id\" = $1]").and_call_original

        subject
      end
    end
  end
end

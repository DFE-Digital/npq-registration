require "rails_helper"

RSpec.describe Migration::Migrators::Application do
  let(:instance) { described_class.new }

  subject { instance.call }

  describe "#call" do
    let(:ecf_npq_application1) { create(:ecf_migration_npq_application) }
    let(:ecf_npq_application2) { create(:ecf_migration_npq_application) }

    before do
      create(:application, ecf_id: ecf_npq_application1.id, **ecf_npq_application1.slice(described_class::ATTRIBUTES_TO_COMPARE))
      create(:application, ecf_id: ecf_npq_application2.id, **ecf_npq_application2.slice(described_class::ATTRIBUTES_TO_COMPARE))

      create(:data_migration, model: :application)
    end

    context "when all attributes values of interest matches" do
      it "migrates the applications" do
        subject

        expect(Migration::DataMigration.find_by(model: :application).processed_count).to eq(2)
        expect(Migration::DataMigration.find_by(model: :application).failure_count).to eq(0)
      end
    end

    context "when any attributes values do not match" do
      before do
        ecf_npq_application1.update!(teacher_catchment: "any")
      end

      it "increments the failure count" do
        subject

        expect(Migration::DataMigration.find_by(model: :application).processed_count).to eq(2)
        expect(Migration::DataMigration.find_by(model: :application).failure_count).to eq(1)
      end

      it "calls FailureManager with correct params" do
        expect_any_instance_of(Migration::FailureManager).to receive(:record_failure).with(ecf_npq_application1, "Validation failed: There are some discrepancies in one or more attributes values").and_call_original

        subject
      end
    end

    context "when an application exists in ECF but cannot be matched to an application in NPQ registration" do
      let!(:ecf_migration_npq_application) { create(:ecf_migration_npq_application) }

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

    context "when an application exists in NPQ registration but cannot be matched to an application in ECF" do
      let!(:npq_application) { create(:application) }

      it "increments the failure count" do
        subject

        expect(Migration::DataMigration.find_by(model: :application).processed_count).to eq(3)
        expect(Migration::DataMigration.find_by(model: :application).failure_count).to eq(1)
      end

      it "calls FailureManager with correct params" do
        expect_any_instance_of(Migration::FailureManager).to receive(:record_failure).with(npq_application, "Couldn't find Migration::Ecf::NpqApplication with [WHERE \"npq_applications\".\"id\" = $1]").and_call_original

        subject
      end
    end
  end
end

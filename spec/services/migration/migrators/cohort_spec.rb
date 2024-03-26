require "rails_helper"

RSpec.describe Migration::Migrators::Cohort do
  let(:instance) { described_class.new }

  subject { instance.call }

  describe "#call" do
    before do
      ecf_cohort1 = create(:ecf_migration_cohort, start_year: 2026)
      ecf_cohort2 = create(:ecf_migration_cohort, start_year: 2029)

      create(:cohort, start_year: ecf_cohort1.start_year)
      create(:cohort, start_year: ecf_cohort2.start_year)

      create(:data_migration, model: :cohort)
    end

    it "migrates the cohorts" do
      subject

      expect(Migration::DataMigration.find_by(model: :cohort).processed_count).to eq(2)
    end

    context "when a cohort is not correctly created" do
      let!(:ecf_migration_cohort) { create(:ecf_migration_cohort, registration_start_date: nil) }

      it "increments the failure count" do
        subject

        expect(Migration::DataMigration.find_by(model: :cohort).processed_count).to eq(3)
        expect(Migration::DataMigration.find_by(model: :cohort).failure_count).to eq(1)
      end

      it "calls FailureManager with correct params" do
        expect_any_instance_of(Migration::FailureManager).to receive(:record_failure).with(ecf_migration_cohort, "Validation failed: Registration start date can't be blank").and_call_original

        subject
      end
    end
  end
end

require "rails_helper"

RSpec.describe Migration::Migrator do
  let(:migration_enabled) { true }
  let(:instance) { described_class.new }

  before { allow(Rails.application.config).to receive(:npq_separation) { { migration_enabled: } } }

  describe ".prepare_for_migration" do
    subject(:prepare) { described_class.prepare_for_migration }

    it { expect { prepare }.to change(Migration::DataMigration, :count).by(3) }

    context "when attempting to prepare multiple times" do
      before { described_class.prepare_for_migration }

      it { expect { prepare }.to raise_error(Migration::Migrator::MigrationAlreadyPreparedError, "The migration has already been prepared") }
    end
  end

  describe "#migrate!" do
    subject(:migrate) { instance.migrate! }

    context "when the migration has been prepared" do
      before { described_class.prepare_for_migration }

      it { expect { migrate }.not_to raise_error }

      it "completes the migration" do
        migrate
        expect(Migration::DataMigration.all.map(&:completed_at)).to be_present
      end

      context "when attempting to migrate multiple times" do
        before { instance.migrate! }

        it { expect { migrate }.to raise_error(Migration::Migrator::MigrationAlreadyRanError, "The migration has already been run") }
      end

      context "when migrating lead providers" do
        before do
          ecf_npq_lead_provider1 = create(:ecf_migration_npq_lead_provider)
          ecf_npq_lead_provider2 = create(:ecf_migration_npq_lead_provider)

          create(:lead_provider, ecf_id: ecf_npq_lead_provider1.id)
          create(:lead_provider, ecf_id: ecf_npq_lead_provider2.id)
        end

        it "migrates the lead providers" do
          migrate

          expect(Migration::DataMigration.find_by(model: :lead_provider).processed_count).to eq(2)
        end

        context "when a lead provider cannot be found" do
          let!(:ecf_migration_npq_lead_provider) { create(:ecf_migration_npq_lead_provider) }

          it "increments the failure count" do
            migrate

            expect(Migration::DataMigration.find_by(model: :lead_provider).processed_count).to eq(3)
            expect(Migration::DataMigration.find_by(model: :lead_provider).failure_count).to eq(1)
          end

          it "calls FailureManager with correct params" do
            expect_any_instance_of(Migration::FailureManager).to receive(:record_failure).with(ecf_migration_npq_lead_provider, "Couldn't find LeadProvider with [WHERE \"lead_providers\".\"ecf_id\" = $1]").and_call_original

            migrate
          end
        end
      end

      context "when migrating cohorts" do
        before do
          ecf_cohort1 = create(:ecf_migration_cohort, start_year: 2026)
          ecf_cohort2 = create(:ecf_migration_cohort, start_year: 2029)

          create(:cohort, start_year: ecf_cohort1.start_year)
          create(:cohort, start_year: ecf_cohort2.start_year)
        end

        it "migrates the cohorts" do
          migrate

          expect(Migration::DataMigration.find_by(model: :cohort).processed_count).to eq(2)
        end

        context "when a cohort is not correctly created" do
          let!(:ecf_migration_cohort) { create(:ecf_migration_cohort, registration_start_date: nil) }

          it "increments the failure count" do
            migrate

            expect(Migration::DataMigration.find_by(model: :cohort).processed_count).to eq(3)
            expect(Migration::DataMigration.find_by(model: :cohort).failure_count).to eq(1)
          end

          it "calls FailureManager with correct params" do
            expect_any_instance_of(Migration::FailureManager).to receive(:record_failure).with(ecf_migration_cohort, "Validation failed: Registration start date can't be blank").and_call_original

            migrate
          end
        end
      end

      context "when migrating statements" do
        before do
          ecf_statement1 = create(:ecf_migration_statement, name: "July 2026")
          ecf_statement2 = create(:ecf_migration_statement, name: "January 2030")

          lead_provider1 = create(:lead_provider, ecf_id: ecf_statement1.npq_lead_provider.id)
          lead_provider2 = create(:lead_provider, ecf_id: ecf_statement2.npq_lead_provider.id)

          create(:statement, month: 7, year: 2026, lead_provider: lead_provider1)
          create(:statement, month: 1, year: 2030, lead_provider: lead_provider2)
        end

        it "migrates the statements" do
          migrate

          expect(Migration::DataMigration.find_by(model: :statement).processed_count).to eq(2)
        end

        context "when a statement is not correctly created" do
          let!(:ecf_migration_statement) { create(:ecf_migration_statement, output_fee: nil) }

          before { create(:lead_provider, ecf_id: ecf_migration_statement.npq_lead_provider.id) }

          it "increments the failure count" do
            migrate

            expect(Migration::DataMigration.find_by(model: :statement).processed_count).to eq(3)
            expect(Migration::DataMigration.find_by(model: :statement).failure_count).to eq(1)
          end

          it "calls FailureManager with correct params" do
            expect_any_instance_of(Migration::FailureManager).to receive(:record_failure).with(ecf_migration_statement, "Validation failed: Output fee is not included in the list").and_call_original

            migrate
          end
        end
      end
    end

    context "when the migration has not been prepared" do
      it { expect { migrate }.to raise_error(Migration::Migrator::MigrationNotPreparedError, "The migration has not been prepared") }
    end

    context "when migration is disabled" do
      let(:migration_enabled) { false }

      it { expect { migrate }.to raise_error(Migration::Migrator::UnsupportedEnvironmentError, "The migration functionality is disabled for this environment") }
    end
  end
end

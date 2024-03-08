require "rails_helper"

RSpec.describe Migration::Migrator do
  let(:migration_enabled) { true }
  let(:instance) { described_class.new }

  before { allow(Rails.application.config).to receive(:npq_separation) { { migration_enabled: } } }

  describe ".prepare_for_migration" do
    subject(:prepare) { described_class.prepare_for_migration }

    it { expect { prepare }.to change(Migration::DataMigration, :count).by(1) }

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

        it "increments the failure count when a lead provider cannot be found" do
          create(:ecf_migration_npq_lead_provider)

          migrate

          expect(Migration::DataMigration.find_by(model: :lead_provider).processed_count).to eq(3)
          expect(Migration::DataMigration.find_by(model: :lead_provider).failure_count).to eq(1)
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

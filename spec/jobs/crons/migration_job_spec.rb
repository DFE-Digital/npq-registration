require "rails_helper"

RSpec.describe Crons::MigrationJob do
  let(:instance) { described_class.new }

  before { allow(Rails.application.config).to receive(:npq_separation) { { migration_enabled: } } }

  it { expect(described_class.cron_expression).to eq("30 0 * * *") }

  describe "#perform" do
    subject(:perform_migration) { instance.perform }

    let(:migration_enabled) { true }
    let(:coordinator_double) { instance_double(Migration::Coordinator, migrate!: nil) }

    before { allow(Migration::Coordinator).to receive(:new).and_return(coordinator_double) }

    it "triggers a migration" do
      perform_migration
      expect(coordinator_double).to have_received(:migrate!).once
    end

    context "when the migration is disabled" do
      let(:migration_enabled) { false }

      it "does not trigger a migration" do
        perform_migration
        expect(coordinator_double).not_to have_received(:migrate!)
      end
    end
  end
end

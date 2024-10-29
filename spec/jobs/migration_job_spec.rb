require "rails_helper"

RSpec.describe MigrationJob do
  let(:instance) { described_class.new }

  describe "#perform" do
    subject(:perform_migration) { instance.perform }

    let(:coordinator_double) { instance_double(Migration::Coordinator, migrate!: nil) }

    before { allow(Migration::Coordinator).to receive(:new).and_return(coordinator_double) }

    it "triggers a migration" do
      perform_migration
      expect(coordinator_double).to have_received(:migrate!).once
    end
  end

  describe "#perform_later" do
    it "enqueues the job exactly once" do
      expect { described_class.perform_later }.to have_enqueued_job(described_class).exactly(:once).on_queue("high_priority")
    end
  end
end

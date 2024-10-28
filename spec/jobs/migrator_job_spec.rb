require "rails_helper"

RSpec.describe MigratorJob do
  let(:instance) { described_class.new }
  let(:migrator) { Migration::Migrators::Cohort }
  let(:worker) { 0 }

  describe "#perform" do
    subject(:perform_migration) { instance.perform(migrator:, worker:) }

    before { Migration::Migrators::Cohort.prepare! }

    it "runs a migrator" do
      expect(migrator).to receive(:call).with(worker:).once

      perform_migration
    end
  end

  describe "#perform_later" do
    it "enqueues the job exactly once" do
      expect { described_class.perform_later(migrator:, worker:) }.to have_enqueued_job(described_class).exactly(:once).on_queue("high_priority")
    end
  end
end

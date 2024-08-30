require "rails_helper"

RSpec.describe MigratorJob do
  let(:instance) { described_class.new }

  describe "#perform" do
    let(:migrator) { Migration::Migrators::Cohort }
    let(:worker) { 0 }

    subject(:perform_migration) { instance.perform(migrator:, worker:) }

    before { Migration::Migrators::Cohort.prepare! }

    it "runs a migrator" do
      expect(migrator).to receive(:call).with(worker:).once

      perform_migration
    end
  end
end

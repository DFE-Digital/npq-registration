require "rails_helper"

RSpec.describe MigrationJob do
  let(:instance) { described_class.new }

  describe "#perform" do
    subject(:perform_migration) { instance.perform }

    let(:migrator_double) { instance_double(Migration::Migrator, migrate!: nil) }

    before { allow(Migration::Migrator).to receive(:new).and_return(migrator_double) }

    it "triggers a migration" do
      perform_migration
      expect(migrator_double).to have_received(:migrate!).once
    end
  end
end

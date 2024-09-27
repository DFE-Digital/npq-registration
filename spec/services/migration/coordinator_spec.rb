require "rails_helper"

RSpec.describe Migration::Coordinator do
  include ActiveJob::TestHelper

  let(:migration_enabled) { true }
  let(:instance) { described_class.new }

  before { allow(Rails.application.config).to receive(:npq_separation) { { migration_enabled: } } }

  describe ".prepare_for_migration" do
    it "calls prepare! on each migrator" do
      expect(Migration::Migrators::Base).to receive(:flush_cache!)
      expect(described_class.migrators).to all(receive(:prepare!))

      described_class.prepare_for_migration
    end
  end

  describe "#migrate!" do
    subject(:migrate) { instance.migrate! }

    it "runs the next runnable migrator" do
      allow(described_class.migrators.first).to receive(:runnable?).and_return(false)
      allow(described_class.migrators.second).to receive(:runnable?).and_return(true)

      expect(described_class.migrators.second).to receive(:queue)

      migrate
    end

    context "when migration is disabled" do
      let(:migration_enabled) { false }

      it { expect { migrate }.to raise_error(described_class::UnsupportedEnvironmentError, "The migration functionality is disabled for this environment") }
    end
  end
end

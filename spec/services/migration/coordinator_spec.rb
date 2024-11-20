require "rails_helper"

RSpec.describe Migration::Coordinator do
  include ActiveJob::TestHelper

  let(:instance) { described_class.new }

  before { allow(Feature).to receive(:ecf_api_disabled?).and_return(true) }

  describe ".prepare_for_migration" do
    it "calls prepare! on each migrator" do
      expect(described_class.migrators).to all(receive(:prepare!))

      described_class.prepare_for_migration
    end
  end

  describe "#migrate!" do
    subject(:migrate) { instance.migrate! }

    it "queues the next runnable migrators" do
      allow(described_class.migrators.first).to receive(:runnable?).and_return(false)
      allow(described_class.migrators.second).to receive(:runnable?).and_return(true)
      allow(described_class.migrators.last).to receive(:runnable?).and_return(true)

      expect(described_class.migrators.first).not_to receive(:queue)
      expect(described_class.migrators.second).to receive(:queue)
      expect(described_class.migrators.last).to receive(:queue)

      migrate
    end

    context "when migration is disabled" do
      before { allow(Feature).to receive(:ecf_api_disabled?).and_return(false) }

      it { expect { migrate }.to raise_error(described_class::UnsupportedEnvironmentError, "The migration functionality is disabled for this environment") }
    end
  end
end

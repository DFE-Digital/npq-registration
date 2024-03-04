require "rails_helper"

RSpec.describe Migration::Migrator do
  let(:migration_enabled) { true }
  let(:instance) { described_class.new }

  before { allow(Rails.application.config).to receive(:npq_separation) { { migration_enabled: } } }

  describe "#migrate!" do
    subject(:migrate) { instance.migrate! }

    before { allow_any_instance_of(described_class).to receive(:sleep) }

    it { expect { migrate }.not_to raise_error }

    it { expect { migrate }.to change(Migration::DataMigration, :count).by(3) }

    context "when migration is disabled" do
      let(:migration_enabled) { false }

      it { expect { migrate }.to raise_error(Migration::Migrator::UnsupportedEnvironmentError, "The migration functionality is disabled for this environment") }
    end
  end
end

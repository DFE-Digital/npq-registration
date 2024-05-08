require "rails_helper"

RSpec.describe Migration::Migrator do
  let(:migration_enabled) { true }
  let(:instance) { described_class.new }

  before { allow(Rails.application.config).to receive(:npq_separation) { { migration_enabled: } } }

  describe "#migrate!" do
    subject(:migrate) { instance.migrate! }

    it { expect { migrate }.not_to raise_error }

    it "calls Migration::Migrators::LeadProvider correctly" do
      expect(Migration::Migrators::LeadProvider).to receive(:call)

      migrate
    end

    it "calls Migration::Migrators::Cohort correctly" do
      expect(Migration::Migrators::Cohort).to receive(:call)

      migrate
    end

    it "calls Migration::Migrators::Statement correctly" do
      expect(Migration::Migrators::Statement).to receive(:call)

      migrate
    end

    it "calls Migration::Migrators::User correctly" do
      expect(Migration::Migrators::User).to receive(:call)

      migrate
    end

    it "calls Migration::Migrators::School correctly" do
      expect(Migration::Migrators::School).to receive(:call)

      migrate
    end

    it "calls Migration::Migrators::Course correctly" do
      expect(Migration::Migrators::Course).to receive(:call)

      migrate
    end

    it "calls Migration::Migrators::Application correctly" do
      expect(Migration::Migrators::Application).to receive(:call)

      migrate
    end

    it "completes the migration" do
      migrate
      expect(Migration::DataMigration.all.map(&:completed_at)).to be_present
    end

    context "when migration is disabled" do
      let(:migration_enabled) { false }

      it { expect { migrate }.to raise_error(Migration::Migrator::UnsupportedEnvironmentError, "The migration functionality is disabled for this environment") }
    end
  end
end

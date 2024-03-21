require "rails_helper"

RSpec.describe Migration::FailuresRecorder, in_memory_rails_cache: true do
  let(:instance) { described_class.new(data_migration:, items:) }

  describe "#record" do
    subject { instance.record }

    context "with correct params" do
      let(:data_migration) { create(:data_migration, model: :statement, failure_count: 2) }
      let(:items) { create_list(:ecf_migration_statement, 2) }

      it "records the failures" do
        subject

        yaml = YAML.load(Rails.cache.read("migration_failures_#{data_migration.model}_#{data_migration.id}"))

        expect(yaml[:model]).to eq("statement")
        expect(yaml.dig(:items, :id).flatten).to match_array(items.map(&:id))
      end
    end

    context "with incorrect params" do
      let(:data_migration) { create(:data_migration) }
      let(:items) { [] }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end
end

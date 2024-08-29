require "rails_helper"

RSpec.describe Migration::FailureManager, :in_memory_rails_cache do
  let(:instance) { described_class.new(data_migration:) }

  describe ".combine_failures" do
    subject(:combined_failures) { described_class.combine_failures(data_migrations) }

    let(:data_migrations) { [failure1, failure2, success1] }
    let(:failure1) { create(:data_migration, :completed, :with_failures) }
    let(:failure2) { create(:data_migration, :completed, :with_failures) }
    let(:success1) { create(:data_migration, :completed) }

    before do
      described_class.new(data_migration: failure1).record_failure(OpenStruct.new(id: 1), "a failure")
      described_class.new(data_migration: failure2).record_failure(OpenStruct.new(id: 2), "a failure")
      described_class.new(data_migration: failure2).record_failure(OpenStruct.new(id: 3), "another failure")
    end

    it "combines the failures" do
      expect(combined_failures).to eq(
        <<~YAML,
          ---
          a failure:
          - 1
          - 2
          another failure:
          - 3
        YAML
      )
    end
  end

  describe "#record_failure" do
    subject { instance.record_failure(item, failure_message) }

    context "with correct params" do
      let(:data_migration) { create(:data_migration, model: :statement, failure_count: 2) }
      let(:item) { create(:ecf_migration_statement) }
      let(:failure_message) { "Test failure" }

      it "records a failure" do
        yaml = YAML.load(subject)

        expect(yaml[failure_message.to_s].first).to eq(item.id)
      end
    end

    context "with incorrect params" do
      let(:data_migration) { create(:data_migration) }
      let(:item) { "" }
      let(:failure_message) { "Test failure" }

      it "returns nil" do
        expect(subject).to be_nil
      end

      context "when data migration is missing" do
        let(:data_migration) { nil }

        it "raises ArgumentError" do
          expect { subject }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe "#all_failures" do
    subject { instance.all_failures }

    context "with correct params" do
      let(:data_migration) { create(:data_migration, model: :statement, failure_count: 2) }
      let(:items) { create_list(:ecf_migration_statement, 2) }

      before do
        instance.record_failure(items.first, "Test failure 1")
        instance.record_failure(items.last, "Test failure 2")
      end

      it "reads the failures" do
        yaml = YAML.load(subject)

        expect(yaml["Test failure 1"].first).to eq(items.first.id)
        expect(yaml["Test failure 2"].first).to eq(items.last.id)
      end
    end

    context "with incorrect params" do
      let(:data_migration) { nil }

      it "raises ArgumentError" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#all_failures_hash" do
    subject(:hash) { instance.all_failures_hash }

    context "with correct params" do
      let(:data_migration) { create(:data_migration, model: :statement, failure_count: 2) }
      let(:items) { create_list(:ecf_migration_statement, 2) }

      before do
        instance.record_failure(items.first, "Test failure 1")
        instance.record_failure(items.last, "Test failure 2")
      end

      it "reads the failures" do
        expect(hash["Test failure 1"].first).to eq(items.first.id)
        expect(hash["Test failure 2"].first).to eq(items.last.id)
      end
    end

    context "with incorrect params" do
      let(:data_migration) { nil }

      it "raises ArgumentError" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end
end

require "rails_helper"

RSpec.describe Migration::Result, type: :model, in_memory_rails_cache: true do
  it { expect(described_class.table_name).to eq("migration_results") }

  describe "scopes" do
    describe "#complete" do
      it "only returns complete migration results" do
        complete_result = create(:migration_result, :complete)
        create(:migration_result, :incomplete)
        expect(described_class.complete).to contain_exactly(complete_result)
      end
    end

    describe "#incomplete" do
      it "returns the incomplete migration results" do
        incomplete_result = create(:migration_result, :incomplete)
        create(:migration_result, :complete)
        expect(described_class.incomplete).to contain_exactly(incomplete_result)
      end
    end

    describe "#ordered_by_most_recent" do
      it "returns the most recent records first" do
        middle = travel_to(1.day.ago) { create(:migration_result) }
        latest = create(:migration_result)
        oldest = travel_to(3.days.ago) { create(:migration_result) }

        expect(described_class.ordered_by_most_recent).to eq([latest, middle, oldest])
      end
    end
  end

  describe ".most_recent_complete" do
    it "returns the most recent complete migration result" do
      travel_to(1.day.ago) { create(:migration_result, :complete) }
      latest = create(:migration_result, :complete)
      travel_to(3.days.ago) { create(:migration_result, :complete) }

      expect(described_class.most_recent_complete).to eq(latest)
    end
  end

  describe ".in_progress" do
    it "returns the most recent in progress migration result (although there should only ever be one in-progress)" do
      create(:migration_result, :complete)
      in_progress = create(:migration_result, :incomplete)
      travel_to(3.days.ago) { create(:migration_result, :incomplete) }

      expect(described_class.in_progress).to eq(in_progress)
    end
  end

  describe "orphan report caching" do
    let(:result) { create(:migration_result) }

    before do
      report = instance_double(Migration::OrphanReport, to_yaml: "--- foo\n")
      result.cache_orphan_report(report, "users")
    end

    describe "#cache_orphan_report" do
      it "caches the report in YAML format" do
        expect(Rails.cache.read("orphaned_users_#{result.id}")).to eq("--- foo\n")
      end
    end

    describe "#cached_orphan_report" do
      it "returns the cached report" do
        expect(result.cached_orphan_report("users")).to eq("--- foo\n")
      end
    end
  end
end

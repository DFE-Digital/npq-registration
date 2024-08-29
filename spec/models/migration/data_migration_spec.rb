require "rails_helper"

RSpec.describe Migration::DataMigration, :in_memory_rails_cache, type: :model do
  subject(:instance) { create(:data_migration) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:model) }
    it { is_expected.to validate_presence_of(:processed_count) }
    it { is_expected.to validate_presence_of(:failure_count) }
    it { is_expected.not_to validate_presence_of(:completed_at) }
    it { is_expected.to validate_presence_of(:worker) }
    it { is_expected.not_to validate_presence_of(:total_count) }

    context "when started_at is present" do
      before { instance.started_at = 1.day.ago }

      it { is_expected.to validate_comparison_of(:completed_at).is_greater_than(instance.started_at).allow_nil }
      it { is_expected.to validate_presence_of(:total_count) }
    end
  end

  describe "defaults" do
    it { expect(instance.processed_count).to eq(0) }
    it { expect(instance.failure_count).to eq(0) }
  end

  describe "scopes" do
    before do
      travel_to(1.day.ago) { create(:data_migration) }
      travel_to(3.days.ago) { create(:data_migration, :completed) }
      travel_to(5.days.ago) { create(:data_migration, :queued) }
      create(:data_migration)
    end

    it { expect(described_class.all).to eq(described_class.all.order(created_at: :asc)) }

    describe ".incomplete" do
      it { expect(described_class.incomplete).to eq(described_class.where(completed_at: nil)) }
    end

    describe ".complete" do
      it { expect(described_class.complete).to eq(described_class.where.not(completed_at: nil)) }
    end

    describe ".queued" do
      it { expect(described_class.queued).to eq(described_class.where.not(queued_at: nil)) }
    end
  end

  describe "#percentage_migrated_successfully" do
    subject { instance.percentage_migrated_successfully }

    it { is_expected.to be(0) }

    context "when processed_count is present" do
      before { instance.processed_count = 100 }

      it { is_expected.to be(100) }

      context "when failure_count is present" do
        before { instance.failure_count = 27 }

        it { is_expected.to be(73) }
      end
    end
  end

  describe "#percentage_migrated" do
    subject { instance.percentage_migrated }

    it { is_expected.to be(0) }

    context "when total_count and processed_count are present" do
      before { instance.assign_attributes(total_count: 96, processed_count: 27) }

      it { is_expected.to be(28) }
    end
  end

  describe "#duration_in_seconds" do
    subject { instance.duration_in_seconds }

    it { is_expected.to be_nil }

    context "when started_at and completed_at are present" do
      before { instance.assign_attributes(started_at: 25.minutes.ago, completed_at: Time.zone.now) }

      it { is_expected.to eq(25.minutes.to_i) }
    end
  end

  describe "#pending?" do
    it { is_expected.to be_pending }

    context "when queued_at is present" do
      before { instance.queued_at = 1.day.ago }

      it { is_expected.not_to be_pending }
    end
  end

  describe "#queued?" do
    it { is_expected.not_to be_queued }

    context "when queued_at is present" do
      before { instance.queued_at = 1.day.ago }

      it { is_expected.to be_queued }
    end
  end

  describe "#in_progress?" do
    it { is_expected.not_to be_in_progress }

    context "when started_at is present" do
      before { instance.started_at = 1.day.ago }

      it { is_expected.to be_in_progress }
    end
  end

  describe "#complete?" do
    it { is_expected.not_to be_complete }

    context "when completed_at is present" do
      before { instance.completed_at = 1.day.ago }

      it { is_expected.to be_complete }
    end
  end

  describe "#name" do
    subject { instance.name }

    it { is_expected.to eq("Model - Worker 1") }
  end
end

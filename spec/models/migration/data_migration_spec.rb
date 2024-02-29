require "rails_helper"

RSpec.describe Migration::DataMigration, type: :model do
  subject(:instance) { described_class.new }

  describe "validations" do
    it { is_expected.to validate_presence_of(:model) }
    it { is_expected.to validate_presence_of(:processed_count) }
    it { is_expected.to validate_presence_of(:failure_count) }
    it { is_expected.not_to validate_presence_of(:completed_at) }

    context "when started_at is present" do
      before { instance.started_at = 1.day.ago }

      it { is_expected.to validate_comparison_of(:completed_at).is_greater_than(instance.started_at).allow_nil }
    end
  end

  describe "defaults" do
    it { expect(instance.processed_count).to eq(0) }
    it { expect(instance.failure_count).to eq(0) }
  end
end

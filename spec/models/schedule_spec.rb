require "rails_helper"

RSpec.describe Schedule, type: :model do
  let(:schedule) { build(:schedule, applies_from: 1.month.ago, applies_to: 1.month.from_now) }

  subject { schedule }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:identifier) }
    it { is_expected.to validate_uniqueness_of(:identifier).scoped_to(:cohort_id) }
    it { is_expected.to validate_presence_of(:applies_from) }
    it { is_expected.to validate_presence_of(:applies_to) }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }
  end

  describe "associations" do
    it { is_expected.to belong_to(:course_group) }
    it { is_expected.to belong_to(:cohort) }
  end

  describe "#editable?" do
    subject { schedule.editable? }

    context "when cohort#editable? is true" do
      before { allow(schedule.cohort).to receive(:editable?).and_return(true) }

      it { is_expected.to be true }
    end

    context "when cohort#editable? is false" do
      before { allow(schedule.cohort).to receive(:editable?).and_return(false) }

      it { is_expected.to be false }
    end
  end
end

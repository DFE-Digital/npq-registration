require "rails_helper"

RSpec.describe Schedule, type: :model do
  let(:schedule) do
    build(
      :schedule,
      applies_from: 1.month.ago,
      applies_to: 1.month.from_now,
      policy_descriptor: 5,
      acceptance_window_start: 2.months.ago,
      acceptance_window_end: 1.month.ago,
    )
  end

  subject { schedule }

  describe "validations" do
    context "with new record" do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_presence_of(:identifier) }
      it { is_expected.to validate_uniqueness_of(:identifier).scoped_to(:cohort_id) }
      it { is_expected.to validate_presence_of(:applies_from) }
      it { is_expected.to validate_presence_of(:applies_to) }
      it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }
      it { is_expected.to validate_numericality_of(:policy_descriptor).only_integer.is_greater_than(0) }
      it { is_expected.to validate_presence_of(:policy_descriptor) }
      it { is_expected.to validate_presence_of(:acceptance_window_start) }
      it { is_expected.to validate_presence_of(:acceptance_window_end) }
      it { is_expected.to be_valid }
    end

    context "with an existing schedule with policy_descriptor, acceptance_window_start and acceptance_window_end" do
      let(:schedule) { create(:schedule, policy_descriptor: 5, acceptance_window_start: 1.day.ago, acceptance_window_end: 2.days.ago) }

      it { is_expected.to validate_presence_of(:policy_descriptor) }
      it { is_expected.to validate_numericality_of(:policy_descriptor).only_integer.is_greater_than(0) }
      it { is_expected.to validate_presence_of(:acceptance_window_start) }
      it { is_expected.to validate_presence_of(:acceptance_window_end) }
    end

    context "with an existing schedule without policy_descriptor, acceptance_window_start and acceptance_window_end" do
      let(:schedule) do
        build(:schedule,
              policy_descriptor: nil,
              acceptance_window_start: nil,
              acceptance_window_end: nil).tap { |s| s.save(validate: false) }
      end

      it { is_expected.not_to validate_presence_of(:policy_descriptor) }
      it { is_expected.not_to validate_presence_of(:acceptance_window_start) }
      it { is_expected.not_to validate_presence_of(:acceptance_window_end) }
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:course_group) }
    it { is_expected.to belong_to(:cohort) }
    it { is_expected.to have_many(:milestones) }
    it { is_expected.to have_many(:statements).through(:milestones) }
  end
end

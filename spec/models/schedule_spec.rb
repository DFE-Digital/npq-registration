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
    it { is_expected.to have_many(:milestones) }
    it { is_expected.to have_many(:statements).through(:milestones) }
  end
end

require "rails_helper"

RSpec.describe Outcome, type: :model do
  subject { build(:outcome) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:state) }
    it { is_expected.to validate_presence_of(:completion_date) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:declaration) }
  end

  describe "completion_date" do
    context "when the completion_date is in the future" do
      it "is not valid" do
        subject.completion_date = 1.day.from_now
        expect(subject).not_to be_valid
        expect(subject.errors[:completion_date]).to include("must be in the future")
      end
    end

    context "when the completion_date is today" do
      it "is valid" do
        subject.completion_date = Time.zone.today
        expect(subject).to be_valid
      end
    end

    context "when the completion_date is in the past" do
      it "is valid" do
        subject.completion_date = 1.day.ago
        expect(subject).to be_valid
      end
    end
  end
end

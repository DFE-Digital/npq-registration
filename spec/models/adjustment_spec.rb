require "rails_helper"

RSpec.describe Adjustment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:statement) }
  end

  describe "validation" do
    it { is_expected.to validate_presence_of(:description).with_message("You must enter a description for the adjustment") }

    context "when amount is blank" do
      subject { build(:adjustment, amount: "") }

      it { is_expected.to validate_presence_of(:amount).with_message "You must enter an adjustment amount" }
    end

    context "when amount is zero" do
      subject { build(:adjustment, amount: 0) }

      it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
    end

    context "when amount is negative" do
      subject { build(:adjustment, amount: -100) }

      it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
    end

    context "when there are non-numeric characters in the amount" do
      subject { build(:adjustment, amount: "100abc") }

      it "validates non-numeric characters" do
        expect(subject.valid?).to be false
        expect(subject.errors[:amount]).to include("You can only enter numeric values in the adjustment amount field")
      end
    end
  end
end

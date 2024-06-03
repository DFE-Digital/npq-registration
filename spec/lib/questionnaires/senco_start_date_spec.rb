require "rails_helper"

RSpec.describe Questionnaires::SencoStartDate, type: :model do
  subject { described_class.new }

  it { is_expected.to validate_presence_of(:senco_start_date) }

  describe "#validate_senco_start_date_in_range?" do
    context "when senco_start_date is not in range" do
      it "adds an error to senco_start_date" do
        subject.senco_start_date = Time.zone.today + 1.day
        subject.validate_senco_start_date_in_range?
        expect(subject.errors[:senco_start_date]).to include("The date you became a SENCO must be in the past")
      end
    end

    context "when senco_start_date is in range" do
      it "does not add an error to senco_start_date" do
        subject.senco_start_date = Time.zone.today - 1.day
        subject.validate_senco_start_date_in_range?
        expect(subject.errors[:senco_start_date]).not_to include("The date you became a SENCO must be in the past")
      end
    end
  end

  describe "#validate_senco_start_date_valid?" do
    context "when date is invalid" do
      it "adds an error to senco_start_date" do
        subject.senco_start_date = { 3 => 1, 2 => 0, 1 => 0 }
        subject.validate_senco_start_date_valid?
        expect(subject.errors[:senco_start_date]).to include("The date you became a SENCO must be a real date")
      end
    end
  end
end

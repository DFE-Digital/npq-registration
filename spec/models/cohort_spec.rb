require "rails_helper"

RSpec.describe Cohort, type: :model do
  describe "validations" do
    describe "#start_year" do
      it { is_expected.to validate_presence_of(:start_year) }

      it {
        expect(subject)
          .to(
            validate_numericality_of(:start_year)
              .is_greater_than_or_equal_to(2021)
              .is_less_than(2030),
          )
      }

      it "validates uniqueness of start_year" do
        existing_cohort = described_class.create!(start_year: 2025)
        new_cohort = described_class.new(start_year: existing_cohort.start_year)

        new_cohort.valid?
        expect(new_cohort.errors[:start_year]).to include("has already been taken")
      end
    end
  end
end

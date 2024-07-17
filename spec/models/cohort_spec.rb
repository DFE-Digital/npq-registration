require "rails_helper"

RSpec.describe Cohort, type: :model do
  subject { build(:cohort) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:registration_start_date) }
    it { is_expected.to allow_value(%w[true false]).for(:funding_cap).with_message("Choose true or false for funding cap") }
    it { is_expected.not_to allow_value(nil).for(:funding_cap).with_message("Choose true or false for funding cap") }

    describe "#registration_start_date_matches_start_year" do
      it "adds an error when the registration_start_date year does not match the start_year" do
        cohort = Cohort.new(start_year: 2022, registration_start_date: Date.new(2023, 4, 10))

        cohort.valid?
        expect(cohort.errors[:registration_start_date]).to include("year must match the start year")
      end

      it "does not add an error when the registration_start_date year matches the start_year" do
        cohort = Cohort.new(start_year: 2022, registration_start_date: Date.new(2022, 4, 10))

        cohort.valid?
        expect(cohort.errors[:registration_start_date]).not_to include("year must match the start year")
      end
    end

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
        existing_cohort = create :cohort, start_year: 2025
        new_cohort = Cohort.new(start_year: existing_cohort.start_year)

        new_cohort.valid?
        expect(new_cohort.errors[:start_year]).to include("has already been taken")
      end
    end
  end

  describe ".current" do
    it "returns the closest cohort in the past" do
      _older_cohort = create(:cohort, start_year: 2021, registration_start_date: Date.new(2021, 4, 10))
      current_cohort = create(:cohort, start_year: 2022, registration_start_date: Date.new(2022, 4, 10))
      _future_cohort = create(:cohort, start_year: 2023, registration_start_date: Date.new(2023, 4, 10))

      expect(Cohort.current(Date.new(2022, 4, 11))).to eq(current_cohort)
    end

    it "includes the Cohort starting exactly on the current date" do
      _older_cohort = create(:cohort, start_year: 2021, registration_start_date: Date.new(2021, 4, 10))
      current_cohort = create(:cohort, start_year: 2022, registration_start_date: Date.new(2022, 4, 10))
      _future_cohort = create(:cohort, start_year: 2023, registration_start_date: Date.new(2023, 4, 10))

      expect(Cohort.current(Date.new(2022, 4, 10))).to eq(current_cohort)
    end

    context "when there is no cohort for the current year" do
      before { travel_to(10.years.ago) }

      it "raises an error" do
        expect { Cohort.current }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

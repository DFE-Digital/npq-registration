require "rails_helper"

RSpec.describe Cohort, type: :model do
  let(:cohort) { create(:cohort) }

  subject { cohort }

  describe "relationships" do
    it { is_expected.to have_many(:declarations).dependent(:restrict_with_exception) }
    it { is_expected.to have_many(:schedules).dependent(:destroy) }
    it { is_expected.to have_many(:statements).dependent(:restrict_with_exception) }
    it { is_expected.to have_many(:delivery_partnerships) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:registration_start_date) }
    it { is_expected.to allow_value(%w[true false]).for(:funding_cap).with_message("Choose true or false for funding cap") }
    it { is_expected.not_to allow_value(nil).for(:funding_cap).with_message("Choose true or false for funding cap") }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }

    describe "registration_start_date year should match start_year" do
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

    describe "start_year" do
      it { is_expected.to validate_presence_of(:start_year) }

      it {
        expect(subject)
          .to(
            validate_numericality_of(:start_year)
              .is_greater_than_or_equal_to(2021)
              .is_less_than(2030),
          )
      }
    end

    describe "#name" do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
      it { is_expected.to validate_length_of(:name).is_at_most(10) }
    end

    describe "#description" do
      it { is_expected.to validate_presence_of(:description) }
      it { is_expected.to validate_uniqueness_of(:description).case_insensitive }
      it { is_expected.to validate_length_of(:description).is_at_least(5).is_at_most(50) }
    end

    describe "changing funding_cap when there are applications" do
      before do
        create(:application, cohort: cohort)
      end

      context "when the funding cap is true" do
        let(:cohort) { create(:cohort, :with_funding_cap) }

        it "does not allow changing the funding_cap" do
          cohort.funding_cap = false
          expect(cohort).to have_error(:funding_cap, "Cannot change funding_cap when there are existing applications for this cohort")
        end
      end

      context "when the funding cap is false" do
        let(:cohort) { create(:cohort, :without_funding_cap) }

        it "does not allow changing the funding_cap" do
          cohort.funding_cap = true
          expect(cohort).to have_error(:funding_cap, "Cannot change funding_cap when there are existing applications for this cohort")
        end
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

require "rails_helper"

RSpec.describe Cohort, type: :model do
  let(:cohort) { create(:cohort) }

  let :suffixed_cohorts do
    (2024..2026).to_a.shuffle.flat_map do |start_year|
      [["a", 4], ["b", 8]].shuffle.map do |suffix, month|
        registration_start_date = Date.new(start_year, month, 10)
        create :cohort, start_year:, suffix:, registration_start_date:
      end
    end
  end

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

    describe "#suffix" do
      it { is_expected.to have_attributes suffix: "a" } # default value when not set
      it { is_expected.to validate_presence_of :suffix }
      it { is_expected.to validate_uniqueness_of(:suffix).scoped_to(:start_year) }
      it { is_expected.to validate_length_of(:suffix).is_at_least(1).is_at_most(1) }
      it { is_expected.to allow_values(*("a".."z").to_a).for(:suffix) }
      it { is_expected.not_to allow_values(*%w[A Z ? ab 123 1 2021a a+]).for(:suffix) }
    end

    describe "#description" do
      it { is_expected.to validate_presence_of(:description) }
      it { is_expected.to validate_uniqueness_of(:description).case_insensitive }
      it { is_expected.to validate_length_of(:description).is_at_least(5).is_at_most(50) }
    end

    describe "#name" do
      subject { create :cohort, start_year: 2029, suffix: "c" }

      it { is_expected.to have_attributes name: "2029c" }
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

  describe ".order_by_latest" do
    subject { described_class.order_by_latest.pluck(:identifier) }

    before { suffixed_cohorts }

    it { is_expected.to eq %w[2026b 2026a 2025b 2025a 2024b 2024a] }
  end

  describe ".order_by_oldest" do
    subject { described_class.order_by_oldest.pluck(:identifier) }

    before { suffixed_cohorts }

    it { is_expected.to eq %w[2024a 2024b 2025a 2025b 2026a 2026b] }
  end

  describe ".prior_to" do
    subject { described_class.prior_to(autumn2025).pluck(:identifier) }

    let(:autumn2025) { suffixed_cohorts && Cohort.find_by!(identifier: "2025b") }

    it { is_expected.to match_array %w[2025a 2024b 2024a] }
  end

  describe ".current" do
    it "returns the closest cohort in the past" do
      current_cohort = create(:cohort, start_year: 2022, registration_start_date: Date.new(2022, 4, 10))
      _older_cohort = create(:cohort, start_year: 2021, registration_start_date: Date.new(2021, 4, 10))
      _future_cohort = create(:cohort, start_year: 2023, registration_start_date: Date.new(2023, 4, 10))

      expect(Cohort.current(Date.new(2022, 4, 11))).to eq(current_cohort)
    end

    it "includes the Cohort starting exactly on the current date" do
      current_cohort = create(:cohort, start_year: 2022, registration_start_date: Date.new(2022, 4, 10))
      _older_cohort = create(:cohort, start_year: 2021, registration_start_date: Date.new(2021, 4, 10))
      _future_cohort = create(:cohort, start_year: 2023, registration_start_date: Date.new(2023, 4, 10))

      expect(Cohort.current(Date.new(2022, 4, 10))).to eq(current_cohort)
    end

    context "when there is no cohort for the current year" do
      before { travel_to(10.years.ago) }

      it "raises an error" do
        expect { Cohort.current }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when there are multiple cohorts for the past year" do
      subject { Cohort.current(Date.new(2022, 4, 11)) }

      before { cohorts }

      let :cohorts do
        {
          current: create(:cohort, start_year: 2022, suffix: "b", registration_start_date: Date.new(2022, 4, 10)),
          older: create(:cohort, start_year: 2022, suffix: "a", registration_start_date: Date.new(2022, 1, 10)),
          future: create(:cohort, start_year: 2023, registration_start_date: Date.new(2023, 4, 10)),
        }
      end

      it { is_expected.to eq(cohorts[:current]) }
    end
  end

  describe "#name" do
    subject { cohort.name }

    context "with suffix of a" do
      it { is_expected.to eq cohort.start_year.to_s }
    end

    context "with any other suffix" do
      let(:cohort) { create(:cohort, suffix: "c") }

      it { is_expected.to eq "#{cohort.start_year}#{cohort.suffix}" }
    end
  end
end

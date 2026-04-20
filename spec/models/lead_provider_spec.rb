require "rails_helper"

RSpec.describe LeadProvider do
  describe "relationships" do
    it { is_expected.to have_many(:applications) }
    it { is_expected.to have_many(:statements) }
    it { is_expected.to have_many(:delivery_partnerships) }
    it { is_expected.to have_many(:delivery_partners).through(:delivery_partnerships) }
    it { is_expected.to have_many(:course_cohort_providers).dependent(:destroy) }
    it { is_expected.to have_many(:course_cohorts).through(:course_cohort_providers) }
    it { is_expected.to have_many(:courses).through(:course_cohorts) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }
  end

  describe "#for" do
    subject { described_class.for(course:, cohort:).map(&:name) }

    let(:cohort) { create(:cohort, :current) }
    let(:course) { Course.first }

    before do
      LeadProviders::Updater.call
      other_course_cohort = create(:course_cohort, course:, cohort: create(:cohort, :previous))
      create(:course_cohort_provider, course_cohort: other_course_cohort, lead_provider: LeadProvider.find_by(name: "Best Practice Network"))
    end

    context "when there is a course cohort for the given course and cohort" do
      let(:course_cohort) { create(:course_cohort, course:, cohort:) }

      before do
        create(:course_cohort_provider, course_cohort:, lead_provider: LeadProvider.find_by(name: "Ambition Institute"))
        create(:course_cohort_provider, course_cohort:, lead_provider: LeadProvider.find_by(name: "LLSE"))
      end

      it "returns the lead providers for the course in the current cohort" do
        expect(subject).to contain_exactly("Ambition Institute", "LLSE")
      end

      context "when cohort is not specified" do
        subject { described_class.for(course:).map(&:name) }

        it "defaults to the current cohort" do
          expect(subject).to contain_exactly("Ambition Institute", "LLSE")
        end
      end
    end

    context "when there isn't a course cohort for the given course and cohort" do
      it "returns an empty scope" do
        expect(subject).to eq LeadProvider.none
      end
    end
  end

  describe "#next_output_fee_statement" do
    let(:cohort) { create(:cohort, :current) }
    let(:lead_provider) { next_output_fee_statement.lead_provider }
    let(:next_output_fee_statement) { create(:statement, :next_output_fee, cohort:) }

    before do
      # Not output fee
      create(:statement, output_fee: false, cohort:, lead_provider:, deadline_date: 1.hour.from_now)
      # Paid
      create(:statement, :paid, :next_output_fee, cohort:, lead_provider:, deadline_date: 2.hours.from_now)
      # Payable
      create(:statement, :payable, :next_output_fee, cohort:, lead_provider:, deadline_date: 3.hours.from_now)
      # Deadline is later
      create(:statement, output_fee: true, cohort:, lead_provider:, deadline_date: 2.days.from_now)
      # Wrong cohort
      create(:statement, output_fee: true, cohort: create(:cohort, start_year: cohort.start_year + 1), lead_provider:, deadline_date: 1.hour.from_now)
      # In the past
      create(:statement, output_fee: true, cohort:, lead_provider:, deadline_date: 1.day.ago)
    end

    subject { lead_provider.next_output_fee_statement(cohort) }

    it { is_expected.to eq(next_output_fee_statement) }
  end

  describe "#delivery_partners_for_cohort" do
    subject { lead_provider.delivery_partners_for_cohort(twenty_three) }

    let :lead_provider do
      create_list(:lead_provider, 2, delivery_partners: {
        twenty_three => twenty_three_partner,
        create(:cohort, start_year: 2024) => twenty_four_partner,
      }).first
    end

    let(:twenty_three) { create(:cohort, start_year: 2023) }
    let(:twenty_three_partner) { create(:delivery_partner) }
    let(:twenty_four_partner) { create(:delivery_partner) }
    let(:unrelated_partner) { create(:delivery_partner) }

    it { is_expected.to have_attributes length: 1 }
    it { is_expected.to include twenty_three_partner }
    it { is_expected.not_to include twenty_four_partner }
    it { is_expected.not_to include unrelated_partner }
  end
end

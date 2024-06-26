require "rails_helper"

RSpec.describe LeadProvider do
  describe "relationships" do
    it { is_expected.to have_many(:applications) }
    it { is_expected.to have_many(:statements) }
  end

  describe "#next_output_fee_statement" do
    let(:cohort) { create(:cohort) }
    let(:lead_provider) { next_output_fee_statement.lead_provider }
    let(:next_output_fee_statement) { create(:statement, :next_output_fee, cohort:) }

    before do
      # Not output fee
      create(:statement, output_fee: false, cohort:, lead_provider:, deadline_date: 1.hour.from_now)
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

  describe "#for" do
    subject { described_class.for(course:).map(&:name) }

    let(:course) { create(:course, identifier: course_identifier) }

    before { LeadProviders::Updater.call }

    context "with course npq-headship" do
      let(:course_identifier) { "npq-headship" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "LLSE",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-senior-leadership" do
      let(:course_identifier) { "npq-senior-leadership" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "LLSE",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-leading-teaching" do
      let(:course_identifier) { "npq-leading-teaching" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "LLSE",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-leading-teaching-development" do
      let(:course_identifier) { "npq-leading-teaching-development" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "LLSE",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-leading-behaviour-culture" do
      let(:course_identifier) { "npq-leading-behaviour-culture" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "LLSE",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-early-headship-coaching-offer" do
      let(:course_identifier) { "npq-early-headship-coaching-offer" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "LLSE",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-additional-support-offer" do
      let(:course_identifier) { "npq-additional-support-offer" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "LLSE",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-early-years-leadership" do
      let(:course_identifier) { "npq-early-years-leadership" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-leading-literacy" do
      let(:course_identifier) { "npq-leading-literacy" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end

    context "with course npq-executive-leadership" do
      let(:course_identifier) { "npq-executive-leadership" }

      it "returns expected lead providers" do
        expect(subject).to eq([
          "Ambition Institute",
          "Best Practice Network (home of Outstanding Leaders Partnership)",
          "Church of England",
          "LLSE",
          "National Institute of Teaching",
          "Teacher Development Trust",
          "Teach First",
          "UCL Institute of Education",
        ])
      end
    end
  end
end

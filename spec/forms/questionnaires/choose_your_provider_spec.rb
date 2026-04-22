require "rails_helper"

RSpec.describe Questionnaires::ChooseYourProvider, type: :model do
  let(:cohort) { create(:cohort, :current) }
  let(:request) { nil }
  let(:valid_lead_provider) { LeadProvider.first }
  let(:current_step) { "choose_your_provider" }

  let(:wizard) do
    RegistrationWizard.new(
      current_step:,
      store:,
      request:,
      current_user: create(:user),
    )
  end

  describe "validations" do
    let(:course) { Course.find_by(identifier: "npq-headship") }
    let(:school) { create(:school) }
    let(:works_in_school) { "yes" }
    let(:chosen_cohort) { cohort }

    let(:store) do
      {
        "teacher_catchment" => "england",
        "course_identifier" => course.identifier,
        "institution_identifier" => "School-#{school.urn}",
        "works_in_school" => works_in_school,
        "course_start_cohort" => chosen_cohort.identifier,
      }
    end

    before do
      course_cohort = create(:course_cohort, course:, cohort: chosen_cohort)
      create(:course_cohort_provider, course_cohort:, lead_provider: valid_lead_provider)
      subject.wizard = wizard
    end

    it { is_expected.to validate_presence_of(:lead_provider_id) }

    context "when the lead provider does not exist" do
      before { subject.lead_provider_id = 0 }

      it { is_expected.to have_error(:lead_provider_id, :invalid, "Choose a valid provider") }
    end

    context "when choosing a lead provider that offers the course in the current cohort" do
      before { subject.lead_provider_id = valid_lead_provider.id }

      it { is_expected.not_to have_error(:lead_provider_id) }
    end

    context "when choosing a lead provider that does not offer the course in the current cohort" do
      before { subject.lead_provider_id = LeadProvider.last.id }

      it { is_expected.to have_error(:lead_provider_id, :invalid, "Choose a valid provider") }
    end

    context "when the chosen cohort is not the current cohort" do
      let(:other_cohort) { create(:cohort, :previous) }
      let(:chosen_cohort) { other_cohort }

      before { cohort }

      context "when choosing a lead provider that offers the course in the current cohort" do
        let(:valid_lead_provider) { LeadProvider.second }

        before { subject.lead_provider_id = valid_lead_provider.id }

        it { is_expected.not_to have_error(:lead_provider_id) }
      end

      context "when choosing a lead provider that does not offer the course in the current cohort" do
        let(:valid_lead_provider) { LeadProvider.second }

        before { subject.lead_provider_id = LeadProvider.first.id }

        it { is_expected.to have_error(:lead_provider_id, :invalid, "Choose a valid provider") }
      end
    end
  end

  describe "#previous_step" do
    let(:current_step) { "choose_your_provider" }
    let(:request) { nil }
    let(:course) { Course.find_by(identifier: "npq-headship") }
    let(:school) { create(:school) }
    let(:works_in_school) { "yes" }
    let(:store) do
      {
        "teacher_catchment" => "england",
        "course_identifier" => course.identifier,
        "institution_identifier" => "School-#{school.urn}",
        "works_in_school" => works_in_school,
        "course_start_cohort" => cohort.identifier,
      }
    end

    let(:wizard) do
      RegistrationWizard.new(
        current_step:,
        store:,
        request:,
        current_user: create(:user),
      )
    end

    let(:mock_funding_service) { instance_double(FundingEligibility, "funded?": true) }

    before do
      subject.wizard = wizard
    end

    context "when npqh and eligible for funding" do
      before do
        allow(FundingEligibility).to receive(:new).and_return(mock_funding_service)
      end

      it "returns :possible_funding" do
        expect(subject.previous_step).to be(:possible_funding)
      end
    end

    context "international journey" do
      let(:store) do
        {
          "teacher_catchment" => "another",
          "course_start_cohort" => cohort.identifier,
        }
      end

      it "returns :funding_your_npq" do
        expect(subject.previous_step).to be(:funding_your_npq)
      end
    end

    context "when not working in school" do
      let(:works_in_school) { "no" }

      it "returns :funding_your_npq" do
        expect(subject.previous_step).to be(:funding_your_npq)
      end
    end
  end

  describe ".options" do
    subject { form.options }

    let(:form) { described_class.new }
    let(:course) { Course.ehco }
    let(:course_identifier) { course.identifier }

    let(:store) do
      {
        "course_identifier" => course_identifier,
        "course_start_cohort" => cohort.identifier,
      }
    end

    before do
      course_cohort = create(:course_cohort, course:, cohort:)
      create(:course_cohort_provider, course_cohort:, lead_provider: valid_lead_provider)
      form.wizard = wizard
    end

    it "returns all providers that offer the course in the current cohort" do
      expect(subject.map(&:value)).to contain_exactly(valid_lead_provider.id)
    end
  end
end

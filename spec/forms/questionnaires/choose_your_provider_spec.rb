require "rails_helper"

RSpec.describe Questionnaires::ChooseYourProvider, type: :model do
  subject(:instance) { described_class.new(wizard:) }

  let(:wizard) { RegistrationWizard.new(current_step: :choose_your_provider, store:, request: nil, current_user: nil) }

  let(:cohort) { create(:cohort, :current) }
  let(:chosen_cohort) { cohort }
  let(:valid_lead_provider) { LeadProvider.first }
  let(:course) { Course.find_by(identifier: "npq-headship") }
  let(:declared_previous_funding) { nil }

  let(:store) do
    {
      course_identifier: course.identifier,
      course_start_cohort: chosen_cohort.identifier,
      declared_previous_funding:,
    }.stringify_keys
  end

  describe "validations" do
    let(:school) { create(:school) }
    let(:works_in_school) { "yes" }

    before do
      course_cohort = create(:course_cohort, course:, cohort: chosen_cohort)
      create(:course_cohort_provider, course_cohort:, lead_provider: valid_lead_provider)
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

  shared_examples_for "eligible or ineligible for funding step based on funding eligibility calculator" do
    context "when eligible for funding" do
      before { allow(FundingEligibility).to receive(:new).and_return(mock_funding_service_funded) }

      it { is_expected.to be(:possible_funding) }
    end

    context "when not eligible for funding" do
      before { allow(FundingEligibility).to receive(:new).and_return(mock_funding_service_not_funded) }

      it { is_expected.to be(:funding_your_npq) }
    end
  end

  describe "#previous_step" do
    subject { instance.previous_step }

    let(:mock_funding_service_funded) { instance_double(FundingEligibility, "funded?": true) }
    let(:mock_funding_service_not_funded) { instance_double(FundingEligibility, "funded?": false, "subject_to_review?": false) }
    let(:mock_funding_service_in_review) { instance_double(FundingEligibility, "funded?": false, "subject_to_review?": true) }

    context "when having declared previous funding" do
      let(:declared_previous_funding) { "yes" }

      it { is_expected.to be(:work_setting) }
    end

    context "when the course is EHCO" do
      let(:course) { Course.find_by(identifier: "npq-early-headship-coaching-offer") }

      context "when declared previous funding" do
        let(:declared_previous_funding) { "yes" }

        it { is_expected.to be(:work_setting) }
      end

      context "when eligible for funding" do
        before { allow(FundingEligibility).to receive(:new).and_return(mock_funding_service_funded) }

        it { is_expected.to be(:ehco_possible_funding) }
      end

      context "when not eligible for funding" do
        it { is_expected.to be(:funding_your_ehco) }
      end
    end

    context "when the course is Leading primary mathematics and eligible for funding" do
      let(:course) { Course.find_by(identifier: "npq-leading-primary-mathematics") }

      before { allow(FundingEligibility).to receive(:new).and_return(mock_funding_service_funded) }

      it { is_expected.to be(:funding_eligibility_maths) }
    end

    context "when the course is SENCO and works in England" do
      let(:course) { Course.find_by(identifier: "npq-senco") }

      before { store["teacher_catchment"] = "england" }

      it { is_expected.to be(:funding_eligibility_senco) }
    end

    context "when working for a lead mentor for an accredited initial teacher training (ITT) provider" do
      before { store["itt_provider"] = IttProvider.currently_approved.first.legal_name }

      it_behaves_like "eligible or ineligible for funding step based on funding eligibility calculator"
    end

    context "when referred by a Return To Teaching Adviser (RTTA)" do
      before { store["referred_by_return_to_teaching_adviser"] = "yes" }

      it_behaves_like "eligible or ineligible for funding step based on funding eligibility calculator"
    end

    context "when subject to review" do
      before { allow(FundingEligibility).to receive(:new).and_return(mock_funding_service_in_review) }

      it { is_expected.to be(:possible_funding) }
    end

    context "when not eligible for funding" do
      before { allow(FundingEligibility).to receive(:new).and_return(mock_funding_service_not_funded) }

      it { is_expected.to be(:funding_your_npq) }
    end
  end

  describe "#next_step" do
    subject { instance.next_step }

    it { is_expected.to be(:share_provider) }
  end

  describe ".options" do
    subject { instance.options }

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
    end

    it "returns all providers that offer the course in the current cohort" do
      expect(subject.map(&:value)).to contain_exactly(valid_lead_provider.id)
    end
  end
end

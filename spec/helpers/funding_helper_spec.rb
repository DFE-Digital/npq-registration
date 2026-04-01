require "rails_helper"

RSpec.describe FundingHelper, type: :helper do
  describe "#scholarship_funding_eligibility" do
    include CourseHelper

    subject { scholarship_funding_eligibility(application) }

    let(:course) { build_stubbed :course, :senior_leadership }
    let(:eligible_for_funding) { false }
    let(:funding_eligiblity_status_code) { :not_in_england }
    let(:raw_application_data) { {} }

    let :application do
      build_stubbed :application, course:,
                                  eligible_for_funding:,
                                  funding_eligiblity_status_code:,
                                  raw_application_data:
    end

    context "with has_ofsted_urn is no" do
      let(:raw_application_data) { { "has_ofsted_urn" => "no" } }

      context "when course is ehco" do
        let(:course) { build_stubbed :course, :early_headship_coaching_offer }

        it { is_expected.to match(/you do not work in England/) }
      end

      context "when course is not ehco" do
        it { is_expected.to match(/not registered on the Ofsted Early Years Register/) }
      end
    end

    context "with unknown status code" do
      let(:funding_eligiblity_status_code) { "unknown" }

      it { is_expected.to be_nil }
    end

    context "with no status code" do
      let(:funding_eligiblity_status_code) { nil }

      it { is_expected.to be_nil }
    end

    context "with status code of :funded" do
      let(:funding_eligiblity_status_code) { "funded" }

      it { is_expected.to eq("You’re not eligible for scholarship funding.") }
    end

    context "with status code of :not_in_england" do
      let(:funding_eligiblity_status_code) { :not_in_england }

      it { is_expected.to match(/you do not work in England/) }
    end

    context "with status code of :ineligible_establishment_type" do
      let(:funding_eligiblity_status_code) { :ineligible_establishment_type }

      it { is_expected.to match(/do not work in one of the eligible settings/) }
    end

    context "with status code of :early_years_invalid_npq" do
      let(:funding_eligiblity_status_code) { :early_years_invalid_npq }

      it { is_expected.to match(/do not work in one of the eligible settings/) }
    end

    context "with status code of :not_lead_mentor_course" do
      let(:funding_eligiblity_status_code) { :not_lead_mentor_course }

      it { is_expected.to match(/do not work in one of the eligible settings/) }
    end

    context "with status code of :ineligible_establishment_not_a_pp50" do
      let(:funding_eligiblity_status_code) { :ineligible_establishment_not_a_pp50 }

      it { is_expected.to match(/not in.*settings that are eligible/) }
    end

    context "with status code of :ineligible_institution_type" do
      let(:funding_eligiblity_status_code) { :ineligible_institution_type }

      it { is_expected.to match(/do not work in one of the eligible settings/) }
    end

    context "with status code of :not_on_early_years_register" do
      let(:funding_eligiblity_status_code) { :not_on_early_years_register }

      it { is_expected.to match(/not registered on the Ofsted Early Years Register/) }
    end

    context "with status code of :not_entitled_ey_institution" do
      let(:funding_eligiblity_status_code) { :not_entitled_ey_institution }

      it { is_expected.to match(/not in.*settings that are eligible/) }
    end

    context "with status code of :not_entitled_childminder" do
      let(:funding_eligiblity_status_code) { :not_entitled_childminder }

      it { is_expected.to match(/not.* Ofsted early years.*or.*Childminder/) }
    end

    context "with status code of :not_new_headteacher_requesting_ehco" do
      let(:funding_eligiblity_status_code) { :not_new_headteacher_requesting_ehco }

      it { is_expected.to match(/not eligible.*Senior leadership/) }
    end

    context "with status code of :previously_funded" do
      let(:funding_eligiblity_status_code) { :previously_funded }

      it { is_expected.to match(/already been allocated scholarship funding/) }
    end

    context "with status code of :referred_by_return_to_teaching_adviser" do
      let(:funding_eligiblity_status_code) { :referred_by_return_to_teaching_adviser }

      it { is_expected.to match(/may be eligible.*subject to review/) }
    end

    context "with status code of :subject_to_review" do
      let(:funding_eligiblity_status_code) { :subject_to_review }

      it { is_expected.to match(/may be eligible.*subject to review/) }
    end
  end
end

# frozen_string_literal: true

RSpec.shared_examples "showing the eligibility step" do
  context "when changing an answer" do
    before { instance.flag_as_changing_answer }

    it { is_expected.to eq(:check_answers) }
  end

  context "when not changing an answer" do
    context "when the course is EHCO" do
      let(:course) {  Course.find_by(identifier: "npq-early-headship-coaching-offer") }

      it { is_expected.to eq(:npqh_status) }
    end

    context "when the course is Leading primary mathematics" do
      let(:course) {  Course.find_by(identifier: "npq-leading-primary-mathematics") }

      it { is_expected.to eq(:maths_eligibility_teaching_for_mastery) }
    end

    context "when the course is SENCO" do
      let(:course) {  Course.find_by(identifier: "npq-senco") }

      it { is_expected.to eq(:senco_in_role) }
    end

    context "when the user is eligible for funding" do
      before do
        allow_any_instance_of(FundingEligibility).to receive(:funding_eligiblity_status_code).and_return(:funded)
      end

      it { is_expected.to eq(:possible_funding) }
    end

    context "when the user is subject to review" do
      before do
        allow_any_instance_of(FundingEligibility).to receive(:funding_eligiblity_status_code).and_return(:subject_to_review)
      end

      it { is_expected.to eq(:possible_funding) }
    end

    context "when the user is not eligible for funding" do
      before do
        allow_any_instance_of(FundingEligibility).to receive(:funding_eligiblity_status_code).and_return(:ineligible_institution_type)
      end

      it { is_expected.to eq(:ineligible_for_funding) }
    end
  end
end

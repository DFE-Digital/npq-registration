require "rails_helper"

RSpec.describe Questionnaires::MathsEligibilityTeachingForMastery, type: :model do
  let(:instance) { described_class.new }
  let(:course) { create(:course, :leading_primary_mathematics) }
  let(:lead_provider) { LeadProvider.for(course:).first }

  let(:store) do
    {
      course_identifier: course.identifier,
      lead_provider_id: lead_provider.id,
    }.stringify_keys
  end

  before do
    instance.wizard = RegistrationWizard.new(
      current_step: :maths_eligibility_teaching_for_mastery,
      store:,
      request: nil,
      current_user: create(:user),
    )
  end

  describe "#next_step" do
    subject { instance.next_step }

    context "when the answer is yes" do
      before { instance.maths_eligibility_teaching_for_mastery = "yes" }

      context "and the funding eligibility status is eligible" do
        before do
          allow_any_instance_of(FundingEligibility).to receive(:funded?).and_return(true)
        end

        it { is_expected.to be :funding_eligibility_maths }
      end

      context "and the funding eligibility status is subject to review" do
        before do
          allow_any_instance_of(FundingEligibility).to receive(:funded?).and_return(false)
          allow_any_instance_of(FundingEligibility).to receive(:subject_to_review?).and_return(true)
        end

        it { is_expected.to be :possible_funding }
      end

      context "and the funding eligibility status is ineligible" do
        before do
          allow_any_instance_of(FundingEligibility).to receive(:funded?).and_return(false)
          allow_any_instance_of(FundingEligibility).to receive(:subject_to_review?).and_return(false)
        end

        it { is_expected.to be :ineligible_for_funding }
      end
    end

    context "when the answer is no" do
      before { instance.maths_eligibility_teaching_for_mastery = "no" }

      it { is_expected.to be :maths_understanding_of_approach }
    end
  end
end

require "rails_helper"

RSpec.describe Questionnaires::MathsUnderstandingOfApproach, type: :model do
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
      current_step: :maths_understanding_of_approach,
      store:,
      request: nil,
      current_user: create(:user),
    )
  end

  describe "#next_step" do
    subject { instance.next_step }

    %w[
      taken_a_similar_course
      another_way
    ].each do |answer|
      context "when the answer is #{answer}" do
        before { instance.maths_understanding_of_approach = answer }

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
    end

    context "when the answer is cannot_show" do
      before { instance.maths_understanding_of_approach = "cannot_show" }

      it { is_expected.to be :maths_cannot_register }
    end
  end
end

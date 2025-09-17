require "rails_helper"

RSpec.describe Questionnaires::SencoInRole, type: :model do
  let(:instance) { described_class.new }
  let(:course) { create(:course, :senco) }
  let(:lead_provider) { LeadProvider.for(course:).first }

  let(:store) do
    {
      course_identifier: course.identifier,
      lead_provider_id: lead_provider.id,
    }.stringify_keys
  end

  before do
    instance.wizard = RegistrationWizard.new(
      current_step: :senco_in_role,
      store:,
      request: nil,
      current_user: create(:user),
    )
  end

  describe "#next_step" do
    subject { instance.next_step }

    context "when the answer is yes" do
      before { instance.senco_in_role = "yes" }

      it { is_expected.to be :senco_start_date }
    end

    %w[
      no_but_i_plan_to_become_one
      no_i_do_not_plan_to_be_a_SENCO
    ].each do |answer|
      context "when the answer is #{answer}" do
        before { instance.senco_in_role = answer }

        context "and the funding eligibility status is eligible" do
          before do
            allow_any_instance_of(FundingEligibility).to receive(:funded?).and_return(true)
          end

          it { is_expected.to be :funding_eligibility_senco }
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
  end
end

require "rails_helper"

RSpec.describe Questionnaires::EhcoNewHeadteacher, type: :model do
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
      current_user: build(:user),
    )
  end

  it { is_expected.to validate_inclusion_of(:ehco_new_headteacher).in_array(Questionnaires::EhcoNewHeadteacher::VALID_EHCO_NEW_HEADTEACHER_OPTIONS) }

  describe "#next_step" do
    subject { instance.next_step }

    context "when the funding eligibility status is eligible" do
      before do
        allow_any_instance_of(FundingEligibility).to receive(:funded?).and_return(true)
      end

      it { is_expected.to be :ehco_possible_funding }
    end

    context "when the funding eligibility status is subject to review" do
      before do
        allow_any_instance_of(FundingEligibility).to receive(:funded?).and_return(false)
        allow_any_instance_of(FundingEligibility).to receive(:subject_to_review?).and_return(true)
      end

      it { is_expected.to be :possible_funding }
    end

    context "when the funding eligibility status is ineligible" do
      before do
        allow_any_instance_of(FundingEligibility).to receive(:funded?).and_return(false)
        allow_any_instance_of(FundingEligibility).to receive(:subject_to_review?).and_return(false)
      end

      context "and the eligibility status is not previously funded" do
        before do
          allow_any_instance_of(FundingEligibility).to receive(:previously_funded?).and_return(false)
        end

        it { is_expected.to be :ehco_funding_not_available }
      end

      context "and the eligibility status is previously funded" do
        before do
          allow_any_instance_of(FundingEligibility).to receive(:previously_funded?).and_return(true)
        end

        it { is_expected.to be :ehco_previously_funded }
      end
    end
  end
end

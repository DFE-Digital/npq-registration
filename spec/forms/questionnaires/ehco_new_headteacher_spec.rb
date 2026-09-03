require "rails_helper"

RSpec.describe Questionnaires::EhcoNewHeadteacher, type: :model do
  let(:instance) { described_class.new }
  let(:course) { create(:course, :senco) }
  let(:lead_provider) { create(:lead_provider) }
  let(:teacher_catchment) { nil }

  let(:store) do
    {
      course_identifier: course.identifier,
      lead_provider_id: lead_provider.id,
      current_user: build_stubbed(:user),
      teacher_catchment:,
    }.stringify_keys
  end

  before do
    create(:course_cohort, :with_provider, course:, cohort: create(:cohort), lead_provider:)
    instance.wizard = RegistrationWizard.new(
      current_step: :senco_in_role,
      store:,
      request: nil,
      current_user: nil,
    )
  end

  it { is_expected.to validate_inclusion_of(:ehco_new_headteacher).in_array(Questionnaires::EhcoNewHeadteacher::VALID_EHCO_NEW_HEADTEACHER_OPTIONS) }

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to be :npqh_status }
  end

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

        it { is_expected.to be :ineligible_for_funding }
      end

      context "and the eligibility status is previously funded" do
        before do
          allow_any_instance_of(FundingEligibility).to receive(:previously_funded?).and_return(true)
        end

        it { is_expected.to be :ineligible_for_funding }
      end

      context "and the user has not answered the catchment question" do
        it { is_expected.to be :ineligible_for_funding }
      end

      context "and the user has answered the catchment question" do
        context "and the user is inside the catchment" do
          let(:teacher_catchment) { "england" }

          it { is_expected.to be :ineligible_for_funding }
        end

        context "and the user is outside the catchment" do
          let(:teacher_catchment) { "another" }

          it { is_expected.to be :funding_your_ehco }
        end
      end
    end
  end
end

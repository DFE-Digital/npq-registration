require "rails_helper"

RSpec.describe Questionnaires::SencoStartDate, type: :model do
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

  it { is_expected.to validate_presence_of(:senco_start_date) }

  describe "#validate_senco_start_date_in_range?" do
    context "when senco_start_date is not in range" do
      it "adds an error to senco_start_date" do
        instance.senco_start_date = Time.zone.today + 1.day
        instance.validate_senco_start_date_in_range?
        expect(instance.errors[:senco_start_date]).to include("The date you became a SENCO must be in the past")
      end
    end

    context "when senco_start_date is in range" do
      it "does not add an error to senco_start_date" do
        instance.senco_start_date = Time.zone.today - 1.day
        instance.validate_senco_start_date_in_range?
        expect(instance.errors[:senco_start_date]).not_to include("The date you became a SENCO must be in the past")
      end
    end
  end

  describe "#validate_senco_start_date_valid?" do
    context "when date is invalid" do
      it "adds an error to senco_start_date" do
        instance.senco_start_date = { 3 => 1, 2 => 0, 1 => 0 }
        instance.validate_senco_start_date_valid?
        expect(instance.errors[:senco_start_date]).to include("The date you became a SENCO must be a real date")
      end
    end
  end

  describe "#next_step" do
    subject { instance.next_step }

    context "when the funding eligibility status is eligible" do
      before do
        allow_any_instance_of(FundingEligibility).to receive(:funded?).and_return(true)
      end

      it { is_expected.to be :funding_eligibility_senco }
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

      it { is_expected.to be :ineligible_for_funding }
    end
  end
end

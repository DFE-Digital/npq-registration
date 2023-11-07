require "rails_helper"

RSpec.describe Eligibility::TargetedFunding do
  subject { described_class.call(institution:, course:, employment_role:) }

  let(:institution) do
    build(:school,
          phase_name:,
          establishment_type_code:)
  end

  let(:establishment_type_code) { eligible_establishment_type_code }
  let(:eligible_establishment_type_code) { 1 }
  let(:course) { instance_double(Course) }
  let(:employment_role) { "Teacher" }
  let(:phase_name) { "Not applicable" }

  describe ".call" do
    context "when the institution is eligible" do
      context "when the institution is in the primary phase of education" do
        let(:phase_name) { School::PRIMARY_PHASE }
        let(:tsf_primary_check_result) do
          {
            tsf_primary_eligibility: true,
            tsf_primary_plus_eligibility: true,
          }
        end

        let(:result) do
          {
            tsf_primary_eligibility: true,
            tsf_primary_plus_eligibility: true,
            targeted_delivery_funding: true,
          }
        end

        before do
          allow(Eligibility::TsfPrimaryEligibility)
            .to receive(:call)
            .with(institution:)
            .and_return(tsf_primary_check_result)
        end

        it "returns result with all checks to be true" do
          expect(subject).to eq(result)
          expect(Eligibility::TsfPrimaryEligibility)
            .to have_received(:call)
            .with(institution:)
        end
      end

      context "when the school is not in the primary phase of education" do
        let(:targeted_delivery_funding) { true }
        let(:result) do
          {
            tsf_primary_eligibility: false,
            tsf_primary_plus_eligibility: false,
            targeted_delivery_funding: true,
          }
        end

        before do
          allow(Eligibility::TargetedDeliveryFunding)
            .to receive(:call)
            .with(institution:, course:, employment_role:)
            .and_return(true)
        end

        it "returns result with primary check to both be false", :aggregate_failures do
          expect(subject).to eq(result)
          expect(Eligibility::TargetedDeliveryFunding)
            .to have_received(:call)
            .with(institution:, course:, employment_role:)
        end
      end
    end

    context "when the institution is ineligible" do
      let(:establishment_type_code) { ineligible_establishment_type_code }
      let(:result) do
        {
          tsf_primary_eligibility: false,
          tsf_primary_plus_eligibility: false,
          targeted_delivery_funding: false,
        }
      end
      let(:ineligible_establishment_type_code) { 0 }

      before do
        allow(Eligibility::TargetedDeliveryFunding)
          .to receive(:call)
          .with(institution:, course:, employment_role:)
          .and_return(false)
      end

      it "returns result with all checks to be false", :aggregate_failures do
        expect(subject).to eq(result)
        expect(Eligibility::TargetedDeliveryFunding)
          .to have_received(:call)
          .with(institution:, course:, employment_role:)
      end
    end
  end
end

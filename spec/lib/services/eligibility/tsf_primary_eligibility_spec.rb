require "rails_helper"

RSpec.describe Services::Eligibility::TsfPrimaryEligibility do
  let(:institution) do
    build(:school,
          phase_name:,
          number_of_pupils: pupil_count)
  end

  let(:result) do
    {
      tsf_primary_eligibility:,
      tsf_primary_plus_eligibility:,
    }
  end
  let(:tsf_primary_eligibility) { true }
  let(:tsf_primary_plus_eligibility) { false }
  let(:phase_name) { School::PRIMARY_PHASE }

  subject { described_class.call(institution:) }

  context "when the institution has equal or less than 150 pupils" do
    let(:tsf_primary_plus_eligibility) { true }
    let(:pupil_count) { 150 }

    it "returns true for both outcomes" do
      expect(subject).to eq(result)
    end
  end

  context "when the institution has over 150 pupils or 0 or nil" do
    [151, 0, nil].each do |pupil_count|
      let(:pupil_count) { pupil_count }

      it "returns true for tsf_primary_eligibility only" do
        expect(subject).to eq(result)
      end
    end
  end

  context "when the institution is not in the primary phase" do
    let(:phase_name) { "Not Applicable" }
    let(:tsf_primary_eligibility) { false }
    let(:pupil_count) { 100 }

    it "returns false for both outcomes" do
      expect(subject).to eq(result)
    end
  end
end

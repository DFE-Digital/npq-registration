require "rails_helper"

RSpec.describe EligibilityList, type: :model do
  let(:urn) { "100001" }
  let(:ukprn) { "12345678" }

  describe ".pp50_school?" do
    context "when the URN is not in the pp50 school list" do
      it "returns false" do
        expect(EligibilityList.pp50_school?(urn)).to be false
      end
    end

    context "when the urn is in the pp50 school list" do
      before { create(:eligibility_list, :pp50_school, identifier: urn) }

      it "returns true" do
        expect(EligibilityList.pp50_school?(urn)).to be true
      end
    end
  end

  describe ".pp50_further_education?" do
    context "when the ukprn is not in the pp50 further education list" do
      it "returns false" do
        expect(EligibilityList.pp50_further_education?(ukprn)).to be false
      end
    end

    context "when the UKPRN is in the pp50 further education list" do
      before { create(:eligibility_list, :pp50_further_education, identifier: ukprn) }

      it "returns true" do
        expect(EligibilityList.pp50_further_education?(ukprn)).to be true
      end
    end
  end

  describe ".childminder?" do
    context "when the URN is not in the childminder list" do
      it "returns false" do
        expect(EligibilityList.childminder?(urn)).to be false
      end
    end

    context "when the URN is in the childminder list" do
      before { create(:eligibility_list, :childminder, identifier: urn) }

      it "returns true" do
        expect(EligibilityList.childminder?(urn)).to be true
      end
    end
  end

  describe ".disadvantaged_early_years_school?" do
    context "when the URN is not in the EY school list" do
      it "returns false" do
        expect(EligibilityList.disadvantaged_early_years_school?(urn)).to be false
      end
    end

    context "when the URN is in the EY school list" do
      before { create(:eligibility_list, :disadvantaged_early_years_school, identifier: urn) }

      it "returns true" do
        expect(EligibilityList.disadvantaged_early_years_school?(urn)).to be true
      end
    end
  end

  describe ".local_authority_nursery?" do
    context "when the URN is not in the LA nursery list" do
      it "returns false" do
        expect(EligibilityList.local_authority_nursery?(urn)).to be false
      end
    end

    context "when the URN is in the LA nursery list" do
      before { create(:eligibility_list, :local_authority_nursery, identifier: urn) }

      it "returns true" do
        expect(EligibilityList.local_authority_nursery?(urn)).to be true
      end
    end
  end

  describe ".rise_school?" do
    context "when the URN is not in the RISE school list" do
      it "returns false" do
        expect(EligibilityList.rise_school?(urn)).to be false
      end
    end

    context "when the URN is in the RISE school list" do
      before { create(:eligibility_list, :rise_school, identifier: urn) }

      it "returns true" do
        expect(EligibilityList.rise_school?(urn)).to be true
      end
    end
  end
end

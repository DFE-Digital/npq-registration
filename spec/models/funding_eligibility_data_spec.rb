require "rails_helper"

RSpec.describe FundingEligibilityData do
  describe "#rise_school?" do
    subject { described_class.new.rise_school?(school) }

    context "with a school on the RISE list" do
      let(:school) { create(:school, urn: "112543") }

      it { is_expected.to be true }
    end

    context "with a URN for a school on the RISE list" do
      let(:school) { "112543" }

      it { is_expected.to be true }
    end

    context "with a school not on the RISE list" do
      let(:school) { create(:school, urn: "123456") }

      it { is_expected.to be false }
    end

    context "with a URN for a school not on the RISE list" do
      let(:school) { "123456" }

      it { is_expected.to be false }
    end
  end
end

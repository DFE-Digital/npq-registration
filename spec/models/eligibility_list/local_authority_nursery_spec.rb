require "rails_helper"

RSpec.describe EligibilityList::LocalAuthorityNursery, type: :model do
  let(:urn) { "100001" }

  describe ".eligible?" do
    subject { described_class.eligible?(urn) }

    context "when the URN is not in the EY school list" do
      it { is_expected.to be false }
    end

    context "when the URN is in the EY school list" do
      before { create(:eligibility_list, :local_authority_nursery, identifier: urn) }

      it { is_expected.to be true }
    end
  end
end

require "rails_helper"

RSpec.describe EligibilityList::Childminder, type: :model do
  let(:urn) { "100001" }

  describe ".eligible?" do
    subject { described_class.eligible?(urn) }

    context "when the URN is not in the childminder list" do
      it { is_expected.to be false }
    end

    context "when the URN is in the childminder list" do
      before { create(:eligibility_list, :childminder, identifier: urn) }

      it { is_expected.to be true }
    end
  end
end

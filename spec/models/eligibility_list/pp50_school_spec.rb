require "rails_helper"

RSpec.describe EligibilityList::Pp50School, type: :model do
  let(:urn) { "100001" }

  describe ".eligible?" do
    subject { described_class.eligible?(urn) }

    context "when the URN is not in the PP50 school list" do
      it { is_expected.to be false }
    end

    context "when the URN is in the pp50 school list" do
      before { create(:eligibility_list_entry, :pp50_school, identifier: urn) }

      it { is_expected.to be true }
    end
  end
end

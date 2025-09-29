require "rails_helper"

RSpec.describe EligibilityList::Pp50FurtherEducation, type: :model do
  let(:ukprn) { "12345678" }

  describe ".eligible?" do
    subject { described_class.eligible?(ukprn) }

    context "when the UKPRN is not in the pp50 further education list" do
      it { is_expected.to be false }
    end

    context "when the UKPRN is in the pp50 further education list" do
      before { create(:eligibility_list, :pp50_further_education, identifier: ukprn) }

      it { is_expected.to be true }
    end
  end
end

require "rails_helper"

RSpec.describe Forms::IttProvider, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:itt_provider) }
  end

  describe "#next_step" do
    let!(:approved_itt_provider) { create(:itt_provider) }

    subject do
      described_class.new(itt_provider: approved_itt_provider.legal_name)
    end

    context "when an approved itt provider" do
      it "returns choose_your_npq" do
        expect(subject.next_step).to eql(:choose_your_npq)
      end
    end
  end
end

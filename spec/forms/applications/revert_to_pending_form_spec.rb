require "rails_helper"

RSpec.describe Applications::RevertToPendingForm, type: :model do
  subject(:instance) { described_class.new(application) }

  let(:application) { create(:application, :accepted) }

  describe "#valid?" do
    it { is_expected.to validate_inclusion_of(:change_status_to_pending).in_array(%w[yes]) }

    context "with lead_provider_approval_status attribute" do
      subject { instance.tap(&:valid?).errors.messages[:lead_provider_approval_status] }

      context "with accepted application" do
        it { is_expected.to be_empty }
      end

      context "with pending application" do
        let(:application) { create(:application, :pending) }

        it { is_expected.not_to be_empty }
      end
    end
  end

  describe "#save" do
    subject { instance.save }

    let(:instance) { described_class.new(application, change_status_to_pending: "yes") }

    context "with valid form" do
      it { is_expected.to be true }
    end

    context "with invalid form" do
      let(:application) { create(:application, :pending) }

      it { is_expected.to be false }
    end
  end
end

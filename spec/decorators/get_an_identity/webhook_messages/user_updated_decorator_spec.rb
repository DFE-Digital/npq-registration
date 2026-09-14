require "rails_helper"

RSpec.describe GetAnIdentity::WebhookMessages::UserUpdatedDecorator do
  let(:instance) { described_class.new(webhook_message) }

  let(:webhook_message) { create(:get_an_identity_webhook_message) }

  describe "#full_name" do
    subject { instance.full_name }

    context "with a middle name" do
      let(:webhook_message) { create(:get_an_identity_webhook_message, middle_name: "Middle") }

      it { is_expected.to eq "John Middle Doe" }
    end

    context "without a middle name" do
      it { is_expected.to eq "John Doe" }
    end
  end
end

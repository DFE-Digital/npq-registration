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

  describe "#date_of_birth" do
    subject { instance.date_of_birth }

    context "with a date of birth" do
      it { is_expected.to eq Date.new(1995, 1, 1) }
    end

    context "without a date of birth" do
      let(:webhook_message) { create(:get_an_identity_webhook_message, date_of_birth: nil) }

      it { is_expected.to be_nil }
    end
  end
end

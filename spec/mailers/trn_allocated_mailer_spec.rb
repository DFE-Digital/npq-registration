require "rails_helper"

RSpec.describe TrnAllocatedMailer, type: :mailer do
  describe "#trn_allocated_mail" do
    let(:user) { build(:user, :with_verified_trn, trn:) }
    let(:to) { user.email }
    let(:full_name) { user.full_name }
    let(:trn) { "2345678" }

    subject(:mail) { described_class.trn_allocated_mail(to:, full_name:, trn:) }

    it "sends to the correct recipient" do
      expect(mail.to).to eq([user.email])
    end

    it "sends the correct personalisation" do
      expect(mail).to have_personalisation(
        full_name: user.full_name,
        trn: user.trn,
      )
    end

    it { is_expected.to use_template(described_class::TEMPLATE_ID) }

    it_behaves_like "a mailer with redacted logs"
  end
end

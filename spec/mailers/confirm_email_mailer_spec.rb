require "rails_helper"

RSpec.describe ConfirmEmailMailer, type: :mailer do
  describe "#confirmation_code_mail" do
    let(:to) { "recipient@example.com" }
    let(:code) { "ABC123" }

    subject(:mail) do
      described_class.confirmation_code_mail(
        to:,
        code:,
      )
    end

    it "sends to the correct recipient" do
      expect(mail.to).to eq([to])
    end

    it { is_expected.to have_personalisation(code:) }
    it { is_expected.to use_template(ConfirmEmailMailer::TEMPLATE_ID) }

    it_behaves_like "a mailer with redacted logs"
  end
end

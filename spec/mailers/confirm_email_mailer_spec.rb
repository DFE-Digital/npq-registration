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

    it "sends the correct personalisation" do
      expect(mail["personalisation"].unparsed_value).to eq({
        code:,
      })
    end

    it "uses the correct template" do
      expect(mail["template-id"].unparsed_value)
        .to eq(ConfirmEmailMailer::TEMPLATE_ID)
    end

    it_behaves_like "a mailer with redacted logs"
  end
end

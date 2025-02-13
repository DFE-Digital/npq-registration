require "rails_helper"

RSpec.describe RegistrationOpenNotificationMailer, type: :mailer do
  describe "#notification_open_mail" do
    let(:to) { "recipient@example.com" }

    subject(:mail) do
      described_class.notification_open_mail(to:)
    end

    it "sends to the correct recipient" do
      expect(mail.to).to eq([to])
    end

    it "uses the correct template" do
      expect(mail["template-id"].unparsed_value)
        .to eq(RegistrationOpenNotificationMailer::TEMPLATE_ID)
    end

    it_behaves_like "a mailer with redacted logs"
  end
end

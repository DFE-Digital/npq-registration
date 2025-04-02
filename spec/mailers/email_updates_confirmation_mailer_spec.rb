require "rails_helper"

RSpec.describe EmailUpdatesConfirmationMailer, type: :mailer do
  describe "#email_updates_confirmation_mail" do
    let(:to) { "recipient@example.com" }
    let(:service_link) { "https://example.com/service" }
    let(:unsubscribe_link) { "https://example.com/unsubscribe" }

    subject(:mail) do
      described_class.email_updates_confirmation_mail(
        to:,
        service_link:,
        unsubscribe_link:,
      )
    end

    it "sends to the correct recipient" do
      expect(mail.to).to eq([to])
    end

    it "sends the correct personalisation" do
      expect(mail).to have_personalisation(
        service_link:,
        unsubscribe_link:,
      )
    end

    it { is_expected.to use_template(EmailUpdatesConfirmationMailer::TEMPLATE_ID) }

    it_behaves_like "a mailer with redacted logs"
  end
end

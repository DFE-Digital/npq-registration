require "rails_helper"

RSpec.describe ApplicationSubmissionMailer, type: :mailer do
  describe "#application_submitted_mail" do
    let(:to) { "recipient@example.com" }
    let(:full_name) { "Example User" }
    let(:provider_name) { "Example Provider" }
    let(:course_name) { "Example Course" }
    let(:amount) { "Example Amount" }
    let(:ecf_id) { "ABC123" }

    subject(:mail) do
      described_class.application_submitted_mail(
        nil,
        to:,
        full_name:,
        provider_name:,
        course_name:,
        amount:,
        ecf_id:,
      )
    end

    it "sends to the correct recipient" do
      expect(mail.to).to eq([to])
    end

    it "sends the correct personalisation" do
      expect(mail["personalisation"].unparsed_value).to eq({
        full_name:,
        provider_name:,
        course_name:,
        amount:,
        ecf_id:,
      })
    end

    it "uses the correct template" do
      expect(mail["template-id"].unparsed_value)
        .to eq(ApplicationSubmissionMailer::TEMPLATE_ID)
    end

    it_behaves_like "a mailer with redacted logs"
  end
end

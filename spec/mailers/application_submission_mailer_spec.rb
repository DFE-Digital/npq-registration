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
      expect(mail).to have_personalisation(
        full_name:,
        provider_name:,
        course_name:,
        amount:,
        ecf_id:,
      )
    end

    it { is_expected.to use_template(ApplicationSubmissionMailer::TEMPLATE_ID) }

    it_behaves_like "a mailer with redacted logs"
  end
end

require "rails_helper"

RSpec.describe ApplicationFundingEligibilityMailer, type: :mailer do
  describe "#eligible_for_funding_mail" do
    let(:to) { "recipient@example.com" }
    let(:full_name) { "Example User" }
    let(:provider_name) { "Example Provider" }
    let(:course_name) { "Example Course" }
    let(:ecf_id) { "ABC123" }

    subject(:mail) do
      described_class.eligible_for_funding_mail(
        to: to,
        full_name: full_name,
        provider_name: provider_name,
        course_name: course_name,
        ecf_id: ecf_id,
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
        ecf_id:,
      })
    end

    it "uses the correct template" do
      expect(mail["template-id"].unparsed_value)
        .to eq(ApplicationFundingEligibilityMailer::ELIGIBLE_FOR_FUNDING_TEMPLATE)
    end

    it_behaves_like "a mailer with redacted logs"
  end
end

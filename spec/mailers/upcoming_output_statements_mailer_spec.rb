require "rails_helper"

RSpec.describe UpcomingOutputStatementsMailer, type: :mailer do
  describe "#email_upcoming_output_statements_mail" do
    let(:to) { "recipient@example.com" }
    let(:this_months_statements) { "something" }
    let(:next_months_statements) { "something else" }

    subject(:mail) do
      described_class.email_upcoming_output_statements_mail(
        to:,
        this_months_statements:,
        next_months_statements:,
      )
    end

    it "sends to the correct recipient" do
      expect(mail.to).to eq([to])
    end

    it { is_expected.to use_template(UpcomingOutputStatementsMailer::TEMPLATE_ID) }
    it { is_expected.to have_personalisation(this_months_statements:, next_months_statements:) }

    it_behaves_like "a mailer with redacted logs"
  end
end

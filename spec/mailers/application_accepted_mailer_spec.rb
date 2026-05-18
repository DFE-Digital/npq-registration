require "rails_helper"

RSpec.describe ApplicationAcceptedMailer, type: :mailer do
  describe "#application_accepted_mail" do
    let(:application) { build(:application, :accepted) }
    let(:to) { application.user.email }
    let(:full_name) { application.user.full_name }
    let(:provider_name) { application.lead_provider.name }
    let(:course_name) { application.course.name }
    let(:ecf_id) { application.ecf_id }

    subject(:mail) { described_class.application_accepted_mail(to:, full_name:, provider_name:, course_name:, ecf_id:) }

    it "sends to the correct recipient" do
      expect(mail.to).to eq([application.user.email])
    end

    it "sends the correct personalisation" do
      expect(mail).to have_personalisation(
        full_name: application.user.full_name,
        provider_name: application.lead_provider.name,
        course_name: application.course.name,
        ecf_id: application.ecf_id,
      )
    end

    it { is_expected.to use_template(described_class::TEMPLATE_ID) }

    it_behaves_like "a mailer with redacted logs"
  end
end

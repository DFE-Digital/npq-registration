require "rails_helper"

RSpec.describe SendApplicationSubmissionEmailJob, type: :job do
  let(:course) { create(:course, :leading_teaching) }
  let(:application) { create(:application, course:, raw_application_data: { "funding_amount" => "123" }) }
  let(:mailer_double) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }

  subject(:job) { described_class.new(application:, email_template: "b8b53310-fa6f-4587-972a-f3f3c6e0892e") }

  describe "#perform" do
    before { allow(ApplicationSubmissionMailer).to receive(:application_submitted_mail) { mailer_double } }

    it "calls `ApplicationSubmissionMailer`" do
      expect(ApplicationSubmissionMailer).to receive(:application_submitted_mail).with(
        "b8b53310-fa6f-4587-972a-f3f3c6e0892e",
        amount: "123",
        to: application.user.email,
        full_name: application.user.full_name,
        provider_name: application.lead_provider.name,
        course_name: "the Leading teaching NPQ",
        ecf_id: application.ecf_id,
      )

      subject.perform_now
    end

    it "delivers the email" do
      expect(mailer_double).to receive(:deliver_now)

      subject.perform_now
    end
  end
end

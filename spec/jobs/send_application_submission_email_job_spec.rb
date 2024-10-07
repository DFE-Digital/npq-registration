require "rails_helper"

RSpec.describe SendApplicationSubmissionEmailJob, type: :job do
  let(:course) { create(:course, :leading_teaching) }
  let(:application) { create(:application, course:, raw_application_data: { "funding_amount" => "123" }) }

  subject(:job) { described_class.new(application:, email_template: "b8b53310-fa6f-4587-972a-f3f3c6e0892e") }

  describe "#perform" do
    context "when ecf_api_disabled flag is toggled off" do
      before { Flipper.disable(Feature::ECF_API_DISABLED) }

      it "does not call `ApplicationSubmissionMailer`" do
        expect(ApplicationSubmissionMailer).not_to receive(:application_submitted_mail)

        job.perform_now
      end
    end

    context "when ecf_api_disabled flag is toggled on" do
      before do
        Flipper.enable(Feature::ECF_API_DISABLED)
        allow(ApplicationSubmissionMailer).to receive(:application_submitted_mail).and_call_original
      end

      it "calls `ApplicationSubmissionMailer`" do
        expect(ApplicationSubmissionMailer).to receive(:application_submitted_mail).with(
          "b8b53310-fa6f-4587-972a-f3f3c6e0892e",
          amount: "123",
          to: application.user.email,
          full_name: application.user.full_name,
          provider_name: application.lead_provider.name,
          course_name: "the Leading teaching NPQ",
        )

        subject.perform_now
      end
    end
  end
end

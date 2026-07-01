require "rails_helper"

RSpec.describe SessionWizardSteps::SignIn, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
  end

  describe "#after_save" do
    subject { described_class.new(email:, wizard:).after_save }

    let(:session) { {} }
    let(:store) { {} }
    let(:admin) { create(:admin) }
    let(:email) { admin.email }
    let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
    let(:wizard) { SessionWizard.new(current_step: :sign_in, store:, session:) }
    let(:otp) { instance_double(OTP, code: String) }
    let(:mailer_double) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }

    before do
      freeze_time
      allow(ConfirmEmailMailer).to receive(:confirmation_code_mail) { mailer_double }
    end

    it "generates an OTP code" do
      expect { subject }.to change { Admin.find(admin.id).otp_hash }.from(nil).to(otp.code)
    end

    it "sets the OTP expiration time" do
      expect { subject }.to change { Admin.find(admin.id).otp_expires_at }.from(nil).to(5.minutes.from_now)
    end

    it "sends an email with the OTP code" do
      expect(ConfirmEmailMailer).to receive(:confirmation_code_mail).with(to: email, code: otp.code)
      expect(mailer_double).to receive(:deliver_now)
      subject
    end

    context "when the admin had failed attempts from a previous code" do
      let(:admin) { create(:admin, otp_failed_attempts: 3) }

      it "resets the failed attempts counter" do
        expect { subject }.to change { admin.reload.otp_failed_attempts }.from(3).to(0)
      end
    end
  end
end

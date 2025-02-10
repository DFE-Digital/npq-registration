require "rails_helper"

RSpec.describe Questionnaires::SignIn, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
  end

  describe "#after_save" do
    subject { described_class.new(email:, wizard:).after_save }

    before { freeze_time }

    let(:session) { {} }
    let(:store) { {} }
    let(:admin) { create(:admin) }
    let(:email) { admin.email }
    let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
    let(:wizard) { SessionWizard.new(current_step: :sign_in, store:, session:) }
    let(:otp_generator) { instance_double(OtpCodeGenerator, call: String) }

    it "generates an OTP code" do
      expect { subject }.to change { Admin.find(admin.id).otp_hash }.from(nil).to(otp_generator.call)
    end

    it "sets the OTP expiration time" do
      expect { subject }.to change { Admin.find(admin.id).otp_expires_at }.from(nil).to(10.minutes.from_now)
    end

    it "sends an email with the OTP code" do
      expect(ConfirmEmailMailer).to receive(:confirmation_code_mail).with(to: email, code: otp_generator.call).and_call_original
      subject
    end
  end
end

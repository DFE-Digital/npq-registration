require "rails_helper"

RSpec.describe SessionWizardSteps::SignInCode, type: :model do
  subject do
    described_class.new(code:)
  end

  let(:admin) { FactoryBot.create(:admin, email: "test@example.com") }
  let(:code) { nil }
  let(:store) { { "email" => admin.email } }
  let(:session) { {} }
  let(:wizard) do
    SessionWizard.new(store:,
                      current_step: "sign_in_code",
                      session:)
  end

  before do
    subject.wizard = wizard
  end

  describe "validations" do
    context "when non existent user" do
      let(:store) { { "email" => "noexist@example.com" } }

      it { is_expected.to validate_presence_of(:code) }
    end

    it { is_expected.to validate_length_of(:code).is_equal_to(8) }

    context "when correct code given" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "ABCD2345", otp_expires_at: 10.minutes.from_now) }
      let(:code) { "ABCD2345" }

      it "passes" do
        expect(subject).to be_valid
      end
    end

    context "when correct code given in lower case" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "ABCD2345", otp_expires_at: 10.minutes.from_now) }
      let(:code) { "abcd2345" }

      it "passes" do
        expect(subject).to be_valid
      end
    end

    context "when code expired" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "ABCD2345", otp_expires_at: 1.minute.ago) }
      let(:code) { "ABCD2345" }

      it "fails" do
        subject.valid?
        expect(subject).to have_error(:code, :expired, "This code has expired. Please request a new code to sign in")
      end
    end

    context "when incorrect code given" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "WXYZ6789", otp_expires_at: 1.minute.ago) }
      let(:code) { "ABCD2345" }

      it "fails" do
        subject.valid?

        expect(subject).to have_error(:code, :incorrect, "Code is not correct. Please try again")
      end
    end

    context "when the user has no stored code" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: nil, otp_expires_at: nil) }
      let(:code) { "ABCD2345" }

      it "is incorrect and does not raise" do
        expect { subject.valid? }.not_to raise_error
        expect(subject).to have_error(:code, :incorrect, "Code is not correct. Please try again")
      end
    end

    context "when the stored code is a legacy 6 digit value" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "123456", otp_expires_at: 10.minutes.from_now) }
      let(:code) { "ABCD2345" }

      it "is incorrect and does not raise" do
        expect { subject.valid? }.not_to raise_error
        expect(subject).to have_error(:code, :incorrect, "Code is not correct. Please try again")
      end
    end

    context "when the stored code has no expiry" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "ABCD2345", otp_expires_at: nil) }
      let(:code) { "ABCD2345" }

      it "is incorrect and does not raise" do
        expect { subject.valid? }.not_to raise_error
        expect(subject).to have_error(:code, :incorrect, "Code is not correct. Please try again")
      end
    end
  end

  describe "failed attempts" do
    let(:admin) { FactoryBot.create(:admin, otp_hash: "ABCD2345", otp_expires_at: 10.minutes.from_now, otp_failed_attempts:) }
    let(:otp_failed_attempts) { 0 }
    let(:code) { "WXYZ6789" }

    context "when a wrong code is entered against a live code" do
      it "records a failed attempt" do
        expect { subject.valid? }.to change { admin.reload.otp_failed_attempts }.from(0).to(1)
        expect(subject).to have_error(:code, :incorrect, "Code is not correct. Please try again")
      end
    end

    context "when a blank code is submitted" do
      let(:code) { "" }

      it "does not record a failed attempt" do
        expect { subject.valid? }.not_to(change { admin.reload.otp_failed_attempts })
      end
    end

    context "when the wrong code is the one that reaches the limit" do
      let(:otp_failed_attempts) { Admin::MAX_OTP_FAILED_ATTEMPTS - 1 }

      it "OTP locks the admin and deletes the stored code" do
        subject.valid?

        expect(admin.reload).to be_otp_locked
        expect(admin.otp_hash).to be_nil
      end
    end

    context "when the admin is already OTP locked" do
      let(:admin) { FactoryBot.create(:admin, :otp_locked) }

      it "shows the locked error and keeps the admin OTP locked" do
        subject.valid?

        expect(subject).to have_error(:code, :locked, "Too many failed attempts. Please request a new code to sign in")
        expect(admin.reload).to be_otp_locked
      end
    end

    context "when the correct code is entered" do
      let(:code) { "ABCD2345" }

      it "is valid, deletes the code and sets no failed attempts" do
        expect(subject).to be_valid
        expect(admin.reload.otp_failed_attempts).to eq(0)
        expect(admin.otp_hash).to be_nil
      end
    end

    context "when the stored code has expired" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "ABCD2345", otp_expires_at: 1.minute.ago, otp_failed_attempts:) }
      let(:code) { "ABCD2345" }

      it "records the expired error and a failed otp attempt" do
        expect { subject.valid? }.to change { admin.reload.otp_failed_attempts }.from(0).to(1)
        expect(subject).to have_error(:code, :expired, "This code has expired. Please request a new code to sign in")
      end
    end

    context "when the email does not match any admin" do
      let(:store) { { "email" => "noexist@example.com" } }

      it "is incorrect and does not raise" do
        expect { subject.valid? }.not_to raise_error
        expect(subject).to have_error(:code, :incorrect, "Code is not correct. Please try again")
      end
    end
  end
end

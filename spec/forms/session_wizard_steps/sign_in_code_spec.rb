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
        expect(subject.errors).to be_of_kind(:code, :expired)
      end
    end

    context "when incorrect code given" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "WXYZ6789", otp_expires_at: 1.minute.ago) }
      let(:code) { "ABCD2345" }

      it "fails" do
        subject.valid?

        expect(subject.errors).to be_of_kind(:code, :incorrect)
      end
    end

    context "when the user has no stored code" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: nil, otp_expires_at: nil) }
      let(:code) { "ABCD2345" }

      it "is incorrect and does not raise" do
        expect { subject.valid? }.not_to raise_error
        expect(subject.errors).to be_of_kind(:code, :incorrect)
      end
    end

    context "when the stored code is a legacy 6 digit value" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "123456", otp_expires_at: 10.minutes.from_now) }
      let(:code) { "ABCD2345" }

      it "is incorrect and does not raise" do
        expect { subject.valid? }.not_to raise_error
        expect(subject.errors).to be_of_kind(:code, :incorrect)
      end
    end

    context "when the stored code has no expiry" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "ABCD2345", otp_expires_at: nil) }
      let(:code) { "ABCD2345" }

      it "is incorrect and does not raise" do
        expect { subject.valid? }.not_to raise_error
        expect(subject.errors).to be_of_kind(:code, :incorrect)
      end
    end
  end
end

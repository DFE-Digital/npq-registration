require "rails_helper"

RSpec.describe Forms::SignInCode, type: :model do
  let(:user) { User.create!(email: "user@example.com") }
  let(:code) { nil }
  let(:store) { { "email" => user.email } }
  let(:session) { {} }
  let(:wizard) do
    SessionWizard.new(store:,
                      current_step: "sign_in_code",
                      session:)
  end

  subject do
    described_class.new(code:)
  end

  before do
    subject.wizard = wizard
  end

  describe "validations" do
    context "when non existent user" do
      let(:store) { { "email" => "noexist@example.com" } }

      it { is_expected.to validate_presence_of(:code) }
    end

    it { is_expected.to validate_length_of(:code).is_equal_to(6) }

    context "when correct code given" do
      let(:user) { User.create!(email: "user@example.com", otp_hash: "123456", otp_expires_at: 10.minutes.from_now) }
      let(:code) { "123456" }

      it "passes" do
        expect(subject.valid?).to be_truthy
      end
    end

    context "when code expired" do
      let(:user) { User.create!(email: "user@example.com", otp_hash: "123456", otp_expires_at: 1.minute.ago) }
      let(:code) { "123456" }

      it "fails" do
        subject.valid?
        expect(subject.errors.of_kind?(:code, :expired)).to be_truthy
      end
    end

    context "when incorrect code given" do
      let(:user) { User.create!(email: "user@example.com", otp_hash: "123456") }
      let(:code) { "111111" }

      it "fails" do
        subject.valid?

        expect(subject.errors.of_kind?(:code, :incorrect)).to be_truthy
      end
    end
  end
end

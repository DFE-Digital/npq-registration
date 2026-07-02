# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "an OTP authenticatable model" do
  let(:factory) { described_class.name.underscore }
  let(:max_attempts) { described_class::MAX_OTP_FAILED_ATTEMPTS }

  describe "#otp_locked?" do
    context "when below the limit" do
      subject { create(factory, otp_failed_attempts: max_attempts - 1) }

      it { is_expected.not_to be_otp_locked }
    end

    context "when at the limit" do
      subject { create(factory, :otp_locked) }

      it { is_expected.to be_otp_locked }
    end
  end

  describe "#otp" do
    subject(:record) { create(factory, otp_hash:, otp_expires_at:) }

    let(:otp_hash) { "ABCD2345" }
    let(:otp_expires_at) { 5.minutes.from_now }

    it "returns the stored code as an OTP" do
      expect(record.otp).to be_a(OTP)
      expect(record.otp).to have_attributes(code: otp_hash, expires_at: otp_expires_at)
    end

    context "when the stored code has expired" do
      let(:otp_expires_at) { 1.minute.ago }

      it "returns an expired OTP" do
        expect(record.otp).to be_a(OTP)
        expect(record.otp).to be_expired
      end
    end

    context "when there is no stored code" do
      let(:otp_hash) { nil }

      it { expect(record.otp).to be_nil }
    end

    context "when the stored code is not a valid format" do
      let(:otp_hash) { "123456" }

      it { expect(record.otp).to be_nil }
    end

    context "when the stored expiry is missing" do
      let(:otp_expires_at) { nil }

      it { expect(record.otp).to be_nil }
    end
  end

  describe "#register_otp_attempt!" do
    subject(:record) { create(factory, otp_hash: "ABCD2345", otp_expires_at: 5.minutes.from_now, otp_failed_attempts: 2) }

    context "when the attempt succeeded" do
      it "clears the stored code and leaves the counter untouched" do
        expect { record.register_otp_attempt!(success: true) }
          .not_to change(record, :otp_failed_attempts)
        expect(record.otp_hash).to be_nil
      end
    end

    context "when the attempt failed" do
      it "records a failed attempt" do
        expect { record.register_otp_attempt!(success: false) }
          .to change(record, :otp_failed_attempts).from(2).to(3)
      end
    end
  end

  describe "#register_failed_otp_attempt!" do
    subject(:record) { create(factory, otp_hash: "ABCD2345", otp_expires_at: 5.minutes.from_now, otp_failed_attempts:) }

    context "when below the limit" do
      let(:otp_failed_attempts) { 0 }

      it "increments the counter and keeps the stored code" do
        expect { record.register_failed_otp_attempt! }
          .to change(record, :otp_failed_attempts).from(0).to(1)
        expect(record.otp_hash).to eq("ABCD2345")
        expect(record).not_to be_otp_locked
      end
    end

    context "when the attempt reaches the limit" do
      let(:otp_failed_attempts) { max_attempts - 1 }

      it "locks the record and deletes the stored code" do
        record.register_failed_otp_attempt!

        expect(record).to be_otp_locked
        expect(record.otp_hash).to be_nil
        expect(record.otp_expires_at).to be_nil
      end
    end
  end
end

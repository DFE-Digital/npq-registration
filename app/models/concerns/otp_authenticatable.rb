module OTPAuthenticatable
  extend ActiveSupport::Concern

  # Requires the including model to have otp_hash, otp_expires_at and otp_failed_attempts columns.
  MAX_OTP_FAILED_ATTEMPTS = 5

  def otp_locked?
    otp_failed_attempts >= MAX_OTP_FAILED_ATTEMPTS
  end

  def otp
    OTP.new(code: otp_hash, expires_at: otp_expires_at)
  rescue OTP::Invalid
    nil
  end

  def register_failed_otp_attempt!
    transaction do
      increment!(:otp_failed_attempts)
      clear_otp! if otp_locked?
    end
  end

  def register_otp_attempt!(success:)
    if success
      clear_otp!
    else
      register_failed_otp_attempt!
    end
  end

  def start_otp!
    OTP.generate.tap do |otp|
      update!(otp_hash: otp.code, otp_expires_at: otp.expires_at, otp_failed_attempts: 0)
    end
  end

private

  def clear_otp!
    update!(otp_hash: nil, otp_expires_at: nil)
  end
end

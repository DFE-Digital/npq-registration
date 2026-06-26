# frozen_string_literal: true

class UserOTPCodeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    otp = user_otp(record.user)

    incorrect_error(record, otp, attribute, value) ||
      expired_error(record, otp, attribute)
  end

private

  def user_otp(user)
    if user && OTP.valid_code_format?(user.otp_hash) && user.otp_expires_at.present?
      OTP.from(code: user.otp_hash, expires_at: user.otp_expires_at)
    end
  end

  def expired_error(record, otp, attribute)
    record.errors.add(attribute, :expired) if otp.expired?
  end

  def incorrect_error(record, otp, attribute, value)
    record.errors.add(attribute, :incorrect) if otp.nil? || !otp.matches?(value)
  end
end

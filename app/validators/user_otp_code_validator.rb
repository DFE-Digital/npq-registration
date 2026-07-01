# frozen_string_literal: true

class UserOTPCodeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    otp = record.user&.otp

    locked_error(record, attribute) ||
      incorrect_error(record, otp, attribute, value) ||
      expired_error(record, otp, attribute)
  end

private

  def expired_error(record, otp, attribute)
    record.errors.add(attribute, :expired) if otp.expired?
  end

  def incorrect_error(record, otp, attribute, value)
    record.errors.add(attribute, :incorrect) if otp.nil? || !otp.matches?(value)
  end

  def locked_error(record, attribute)
    record.errors.add(attribute, :locked) if record.user&.otp_locked?
  end
end

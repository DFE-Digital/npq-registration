# frozen_string_literal: true

class ValidateAndCopyErrorsValidator < ActiveModel::EachValidator
  def validate_each(record, _attribute, value)
    return unless value

    record.errors.merge!(value.errors) unless value.valid?
  end
end

# frozen_string_literal: true

class ValidTrnValidator < ActiveModel::EachValidator
  FORBIDDEN_TRNS = %w[0000000].freeze

  def validate_each(record, attribute, value)
    if FORBIDDEN_TRNS.include?(value)
      record.errors.add(attribute, :not_real)
    end
    if value.blank?
      record.errors.add(attribute, :blank)
    elsif value !~ /\A\d+\z/
      record.errors.add(attribute, :invalid, message: I18n.t("errors.attributes.trn.invalid"))
    elsif value.length != 7
      record.errors.add(attribute, :wrong_length, count: 7)
    end
  end
end

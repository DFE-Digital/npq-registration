# frozen_string_literal: true

class DeclarationDateValidator < ActiveModel::Validator
  RFC3339_DATE_REGEX = /\A\d{4}-\d{2}-\d{2}T(\d{2}):(\d{2}):(\d{2})([.,]\d+)?(Z|[+-](\d{2})(:?\d{2})?)?\z/i

  def validate(record)
    return if record.errors.any?

    date_has_the_right_format(record)
    declaration_within_schedule(record)
  end

private

  def date_has_the_right_format(record)
    return if record.raw_declaration_date.blank?
    return if record.raw_declaration_date.match?(RFC3339_DATE_REGEX) && begin
      Time.zone.parse(record.raw_declaration_date.to_s)
    rescue ArgumentError
      false
    end

    record.errors.add(:declaration_date, :invalid)
  end

  def declaration_within_schedule(record)
    return unless record.schedule && record.declaration_date.present?

    if record.declaration_date < record.schedule.applies_from.beginning_of_day
      record.errors.add(:declaration_date, :declaration_before_schedule_start)
    end

    if record.schedule.applies_to.end_of_day <= record.declaration_date
      record.errors.add(:declaration_date, :declaration_after_schedule_cutoff)
    end
  end
end

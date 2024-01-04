class FutureDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.present? && value < Time.zone.now
      record.errors.add(attribute, "must be in the future")
    end
  end
end

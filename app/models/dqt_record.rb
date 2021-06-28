class DqtRecord
  include ActiveModel::Model

  attr_accessor :teacher_reference_number,
                :full_name,
                :national_insurance_number,
                :active_alert

  attr_reader :qts_date, :date_of_birth

  def self.find(trn:)
    hash = Services::DqtClient.new(trn: trn).call

    return if hash.nil?

    DqtRecord.new(hash)
  end

  def qts_date=(value)
    @qts_date = Date.parse(value)
  end

  def date_of_birth=(value)
    @date_of_birth = Date.parse(value)
  end

  def fuzzy_match?(full_name:, date_of_birth:, national_insurance_number:)
    [
      self.full_name == full_name,
      self.date_of_birth == date_of_birth,
      self.national_insurance_number.downcase == national_insurance_number.downcase,
    ].count(true) > 1
  end
end

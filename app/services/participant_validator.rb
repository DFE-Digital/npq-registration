class ParticipantValidator
  attr_reader :trn, :full_name, :date_of_birth, :national_insurance_number

  MIN_TOTAL_DQT_CHECK_MATCHES_TO_BE_VERIFIED = 3

  def initialize(trn:, full_name:, date_of_birth:, national_insurance_number: nil)
    @trn = trn
    @full_name = full_name
    @date_of_birth = date_of_birth
    @national_insurance_number = national_insurance_number
  end

  def call
    result = Dqt::RecordCheck.new(**payload.merge(check_first_name_only: true)).call
    if result.total_matched >= MIN_TOTAL_DQT_CHECK_MATCHES_TO_BE_VERIFIED
      result.dqt_record
    end
  end

private

  def payload
    { trn:, full_name:, date_of_birth: dob_as_string, nino: national_insurance_number }
  end

  def dob_as_string
    date_of_birth.iso8601
  end
end

module Services
  class FakeParticipantValidator
    attr_reader :trn, :full_name, :date_of_birth, :national_insurance_number

    def initialize(trn:, full_name:, date_of_birth:, national_insurance_number: nil)
      @trn = trn
      @full_name = full_name
      @date_of_birth = date_of_birth
      @national_insurance_number = national_insurance_number
    end

    def call
      if first_name.match?(/John|Jane/)
        OpenStruct.new(trn: trn, qts: true, active_alert: false)
      end
    end

  private

    def first_name
      full_name.split(" ").first
    end
  end
end

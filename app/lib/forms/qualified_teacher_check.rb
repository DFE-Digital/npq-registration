module Forms
  class QualifiedTeacherCheck < Base
    include ActiveRecord::AttributeAssignment

    attr_accessor :trn, :full_name, :national_insurance_number

    attr_reader :date_of_birth

    def date_of_birth=(value)
      @date_of_birth_invalid = false
      @date_of_birth = ActiveRecord::Type::Date.new.cast(value)
    rescue StandardError => _e
      @date_of_birth_invalid = true
    end

    validates :trn, presence: true, length: { in: 7..10 }
    validates :full_name, presence: true, length: { maximum: 128 }
    validate :validate_date_of_birth_valid?
    validates :date_of_birth, presence: true
    validate :validate_date_of_birth_in_the_past?
    validates :national_insurance_number, length: { maximum: 9 }

    def self.permitted_params
      %i[
        trn
        full_name
        date_of_birth
        national_insurance_number
      ]
    end

    def next_step
      record = DqtRecord.find(trn: trn)

      if record && record.fuzzy_match?(
        full_name: full_name,
        date_of_birth: date_of_birth,
        national_insurance_number: national_insurance_number,
      )
        :choose_your_npq
      else
        :dqt_mismatch
      end
    end

    def previous_step
      :contact_details
    end

  private

    def validate_date_of_birth_in_the_past?
      if date_of_birth && (date_of_birth > Time.zone.now)
        errors.add(:date_of_birth, :in_future)
      end
    end

    def validate_date_of_birth_valid?
      if @date_of_birth_invalid
        errors.add(:date_of_birth, :invalid)
      end
    end
  end
end

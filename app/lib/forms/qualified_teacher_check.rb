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

    validates :trn, presence: true, length: { is: 7 }, format: { with: /\A\d{7}\z/ }
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
      record = DqtRecord.find(trn: trn_digits_only)

      @active_alert = record && record.active_alert
      if record && record.fuzzy_match?(
        full_name: full_name,
        date_of_birth: date_of_birth,
        national_insurance_number: national_insurance_number,
      )
        mark_trn_as_verified

        if changing_answer?
          :check_answers
        else
          :choose_your_npq
        end
      else
        mark_trn_as_unverified

        :dqt_mismatch
      end
    rescue StandardError => e
      Sentry.capture_exception(e)

      mark_trn_as_unverified

      :dqt_mismatch
    end

    def previous_step
      :contact_details
    end

    def trn_verified?
      @trn_verified
    end

    def active_alert?
      @active_alert
    end

    def after_save
      wizard.store["trn_verified"] = trn_verified?
      wizard.store["active_alert"] = active_alert?
    end

  private

    def trn_digits_only
      trn.scan(/\d/).join
    end

    def mark_trn_as_verified
      @trn_verified = true
    end

    def mark_trn_as_unverified
      @trn_verified = false
    end

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

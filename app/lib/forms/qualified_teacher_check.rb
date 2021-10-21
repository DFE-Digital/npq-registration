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

    before_validation :strip_full_name_whitespace
    before_validation :convert_full_name_smart_quotes
    before_validation :strip_trn_whitespace
    before_validation :strip_ni_number_whitespace
    before_validation :strip_title_prefixes

    validates :trn, presence: true
    validates :full_name, presence: true, length: { maximum: 128 }
    validate :validate_processed_trn
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

    def validate_processed_trn
      if processed_trn !~ /\A\d+\z/
        errors.add(:trn, :invalid)
      elsif processed_trn.length < 5
        errors.add(:trn, :too_short, count: 5)
      elsif processed_trn.length > 7
        errors.add(:trn, :too_long, count: 7)
      end
    end

    def processed_trn
      @processed_trn ||= (trn || "").gsub("RP", "").gsub("/", "")
    end

    def next_step
      record = Services::ParticipantValidator.new(
        trn: trn_digits_only,
        full_name: full_name,
        date_of_birth: date_of_birth,
        national_insurance_number: national_insurance_number,
      ).call

      if record
        mark_trn_as_verified
        mark_trn_as_auto_verified
        store_verified_trn(record)
        store_active_alert(record)

        if changing_answer?
          :check_answers
        else
          :find_school
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

    def store_verified_trn(record)
      @verified_trn = record.trn
    end

    def store_active_alert(record)
      @active_alert = record.active_alert
    end

    def previous_step
      :contact_details
    end

    def trn_verified?
      @trn_verified
    end

    def trn_auto_verified?
      @trn_auto_verified
    end

    def active_alert?
      @active_alert
    end

    def after_save
      wizard.store["trn_verified"] = trn_verified?
      wizard.store["trn_auto_verified"] = trn_auto_verified?
      wizard.store["verified_trn"] = verified_trn
      wizard.store["active_alert"] = active_alert?
    end

  private

    attr_reader :verified_trn

    def strip_full_name_whitespace
      full_name&.squish!
    end

    def convert_full_name_smart_quotes
      full_name&.tr!("’", "'")
    end

    def strip_trn_whitespace
      trn&.gsub!(" ", "")
    end

    def strip_ni_number_whitespace
      national_insurance_number&.gsub!(" ", "")
    end

    def trn_digits_only
      trn.scan(/\d/).join
    end

    def mark_trn_as_verified
      @trn_verified = true
    end

    def mark_trn_as_auto_verified
      @trn_auto_verified = true
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

    def strip_title_prefixes
      full_name&.sub!(/^Mr\.* |^Mrs\.* |^Miss\.* |^Ms\.* /i, "")
    end
  end
end

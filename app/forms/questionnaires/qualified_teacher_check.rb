module Questionnaires
  class QualifiedTeacherCheck < Base
    include ActiveRecord::AttributeAssignment

    FORBIDDEN_TRNS = %w[0000000].freeze

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
    validate :validate_processed_trn

    validates :full_name, presence: true, length: { maximum: 128 }

    validates :date_of_birth, presence: true
    validate :validate_date_of_birth_valid?
    validate :validate_date_of_birth_in_the_past?

    validates :national_insurance_number, presence: true, if: :ni_number_required?
    validates :national_insurance_number, length: { maximum: 9 }

    def self.permitted_params
      %i[
        trn
        full_name
        date_of_birth
        national_insurance_number
      ]
    end

    def questions
      [
        QuestionTypes::TextField.new(
          name: :trn,
        ),

        QuestionTypes::TextField.new(
          name: :full_name,
          additional_info: true,
        ),

        QuestionTypes::DateField.new(
          name: :date_of_birth,
        ),

        QuestionTypes::TextField.new(
          name: :national_insurance_number,
          locale_name: nin_locale,
        ),
      ]
    end

    def requirements_met?
      # The user has to have logged in via GAI to reach this question
      wizard.store.present? && query_store.current_user.present?
    end

    def validate_processed_trn
      if FORBIDDEN_TRNS.include?(processed_trn)
        errors.add(:trn, :not_real)
      end
      if processed_trn !~ /\A\d+\z/
        errors.add(:trn, :invalid)
      elsif processed_trn.length < 7
        errors.add(:trn, :too_short, count: 7)
      elsif processed_trn.length > 7
        errors.add(:trn, :too_long, count: 7)
      end
    end

    def processed_trn
      @processed_trn ||= trn || ""
    end

    def next_step
      record = ParticipantValidator.new(
        trn: trn_digits_only,
        full_name:,
        date_of_birth:,
        national_insurance_number:,
      ).call

      if record
        mark_trn_as_verified
        mark_trn_as_auto_verified
        store_verified_trn(record)
        store_active_alert(record)

        return :check_answers if changing_answer?

        :course_start_date
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
      :start
    end

    def store_verified_trn(record)
      @verified_trn = record.trn
    end

    def store_active_alert(record)
      @active_alert = record.active_alert
    end

    def trn_verified?
      @trn_verified
    end

    def trn_lookup_status
      # This mimics the lookup status that the get an identity service would give
      trn_verified? ? "Found" : "Failed"
    end

    def trn_auto_verified?
      @trn_auto_verified
    end

    def active_alert?
      @active_alert
    end

    def before_render
      # Load info from current_user into store if it isn't already set
      # This way this info will be pre-populated in the forms.
      # This is useful for when the user is logged in and we already know this info.
      @full_name ||= query_store.current_user.full_name
      @trn ||= query_store.current_user.trn
      @date_of_birth ||= query_store.current_user.date_of_birth # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    def after_save
      wizard.store["trn_verified"] = trn_verified?
      wizard.store["trn_lookup_status"] = trn_lookup_status
      wizard.store["trn_auto_verified"] = trn_auto_verified?
      wizard.store["verified_trn"] = verified_trn
      wizard.store["active_alert"] = active_alert?

      query_store.current_user.update!(
        trn: trn_to_store,
        full_name:,
        date_of_birth:,
        national_insurance_number: ni_number_to_store,
        trn_verified: trn_verified?,
        trn_lookup_status:,
        trn_auto_verified: !!trn_auto_verified?,
        active_alert: active_alert?,
      )
      wizard.store["trn_set_via_fallback_verification_question"] = true
    end

    def ni_number_required?
      wizard.query_store.inside_catchment?
    end

  private

    attr_reader :verified_trn

    def trn_to_store
      if trn_verified? && verified_trn.present?
        verified_trn.rjust(7, "0")
      else
        trn.rjust(7, "0")
      end
    end

    def ni_number_to_store
      national_insurance_number unless trn_verified?
    end

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

    def nin_locale
      ni_number_required? ? :national_insurance_number : :national_insurance_number_optional
    end
  end
end

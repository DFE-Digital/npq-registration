module Questionnaires
  class SencoStartDate < Base
    include ActiveModel::Attributes
    include ActiveRecord::AttributeAssignment
    include Helpers::Institution

    QUESTION_NAME = :senco_start_date

    attr_reader QUESTION_NAME

    def senco_start_date=(value)
      @senco_start_date_invalid = false
      @senco_start_date = ActiveRecord::Type::Date.new.cast(value)
    rescue StandardError => _e
      @senco_start_date_invalid = true
    end

    validate :validate_senco_start_date_valid?
    validate :validate_senco_start_date_in_the_past?

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def after_save
      wizard.store["senco_start_date"] = senco_start_date
    end

    def questions
      [
        QuestionTypes::DateField.new(
          name: :senco_start_date,
          style_options: { omit_day: true, legend: { size: "xl", tag: "h1" } },
        ),
      ]
    end

    def next_step
      if !wizard.query_store.teacher_catchment_england? || wizard.query_store.kind_of_nursery_private?
        :ineligible_for_funding
      elsif wizard.query_store.works_in_other? && wizard.query_store.lead_mentor_for_accredited_itt_provider?
        :ineligible_for_funding
      else
        :funding_eligibility_senco
      end
    end

    def previous_step
      :senco_in_role
    end

    def validate_senco_start_date_in_the_past?
      if senco_start_date && (senco_start_date > Time.zone.now)
        errors.add(:senco_start_date, :in_future)
      end
    end

    def validate_senco_start_date_valid?
      errors.add(:senco_start_date, :invalid) if @senco_start_date_invalid
    end
  end
end

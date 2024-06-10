module Questionnaires
  class SencoStartDate < Base
    include ActiveModel::Attributes
    include ActiveRecord::AttributeAssignment
    include Helpers::Institution

    QUESTION_NAME = :senco_start_date
    EARLIEST_SENCO_START_DATE = Date.new(1960, 1, 1)

    attr_reader QUESTION_NAME

    def senco_start_date=(value)
      @senco_start_date_invalid = false
      @senco_start_date = ActiveRecord::Type::Date.new.cast(value)
    rescue StandardError => _e
      @senco_start_date_invalid = true
    end

    validate :validate_senco_start_date_valid?
    validate :validate_senco_start_date_in_range?

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
      if funding_eligibility.funded?
        :funding_eligibility_senco
      elsif works_in_other? && !employment_type_other? && funding_eligibility.funding_eligiblity_status_code == FundingEligibility::NO_INSTITUTION
        :possible_funding
      else
        :ineligible_for_funding
      end
    end

    def funding_eligibility
      @funding_eligibility ||= FundingEligibility.new(
        course:,
        institution:,
        approved_itt_provider: approved_itt_provider?,
        lead_mentor_for_accredited_itt_provider: lead_mentor_for_accredited_itt_provider?,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
        trn:,
        get_an_identity_id:,
      )
    end

    def previous_step
      :senco_in_role
    end

    def validate_senco_start_date_in_range?
      if senco_start_date && !senco_start_date.between?(EARLIEST_SENCO_START_DATE, Time.zone.today)
        errors.add(:senco_start_date, :in_future)
      end
    end

    def validate_senco_start_date_valid?
      errors.add(:senco_start_date, :invalid) if @senco_start_date_invalid
    end

    delegate :course, :lead_mentor_for_accredited_itt_provider?, :new_headteacher?, :inside_catchment?,
             :approved_itt_provider?, :get_an_identity_id, :trn, :works_in_other?, :employment_type_other?, to: :query_store
  end
end

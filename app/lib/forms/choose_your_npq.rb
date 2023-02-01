module Forms
  class ChooseYourNpq < Base
    include Helpers::Institution

    QUESTION_NAME = :choose_your_npq

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true
    validate :validate_course_exists

    def self.permitted_params
      [QUESTION_NAME.to_sym]
    end

    def question
      Forms::QuestionTypes::RadioButtonGroup.new(
        name: :choose_your_npq,
        options:,
      )
    end

    def options
      [
        build_option_struct(value: "leading_behaviour_and_culture", link_errors: true),
        build_option_struct(value: "leading_literacy"),
        build_option_struct(value: "leading_teaching"),
        build_option_struct(value: "leading_teacher_development"),
        build_option_struct(value: "senior_leadership"),
        build_option_struct(value: "headship"),
        build_option_struct(value: "executive_leadership"),
        build_option_struct(value: "early_years_leadership"),
        build_option_struct(value: "early_headship_coaching_offer", divider: true),
      ]
    end

    def after_save
      wizard.store["course_id"] = course.id.to_s

      return if lead_provider_valid?

      wizard.store["lead_provider_id"] = nil
    end

    def next_step
      # If your lead provider remains valid we can progress down the changing answer path
      # as it is fine for us to end up going back to the check_answers page.
      # If it is no longer valid due to the NPQ changing though we will need to be
      # reinserted back into the flow so that later on the user can be asked to
      # choose a new provider.
      if changing_answer? && lead_provider_valid?
        if no_answers_will_change?
          :check_answers
        elsif course.ehco?
          :about_ehco
        elsif previously_eligible_for_funding? && !eligible_for_funding?
          if wizard.query_store.works_in_other?
            :choose_your_provider
          else
            :ineligible_for_funding
          end
        else
          :check_answers
        end
      elsif course.ehco?
        :about_ehco
      elsif eligible_for_funding?
        :possible_funding
      elsif wizard.query_store.works_in_other?
        :choose_your_provider
      else
        :ineligible_for_funding
      end
    end

    def previous_step
      if query_store.inside_catchment? && query_store.works_in_school?
        :choose_school
      elsif query_store.inside_catchment? && query_store.works_in_childcare?
        if query_store.kind_of_nursery_public?
          :choose_childcare_provider
        elsif query_store.has_ofsted_urn?
          :choose_private_childcare_provider
        else
          :have_ofsted_urn
        end
      elsif wizard.tra_get_an_identity_omniauth_integration_active?
        :work_setting
      else
        :qualified_teacher_check
      end
    end

    def course
      courses.find_by(name: ::Course::LEGACY_NAME_MAPPING[choose_your_npq])
    end

  private

    def lead_provider_valid?
      valid_providers.include?(wizard.query_store.lead_provider)
    end

    def valid_providers
      LeadProvider.for(course:)
    end

    def courses
      Course.where(display: true).order(:position)
    end

    def previous_course
      Course.find_by(id: wizard.store["choose_your_npq"])
    end

    def previously_eligible_for_funding?
      Services::FundingEligibility.new(
        course: previous_course,
        institution:,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
        trn: wizard.query_store.trn,
      ).funded?
    end

    def funding_eligibility_calculator
      @funding_eligibility_calculator ||= Services::FundingEligibility.new(
        course:,
        institution:,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
        trn: wizard.query_store.trn,
      )
    end

    def eligible_for_funding?
      funding_eligibility_calculator.funded?
    end

    delegate :ineligible_institution_type?, to: :funding_eligibility_calculator
    delegate :new_headteacher?, :inside_catchment?, to: :query_store

    def validate_course_exists
      if course.blank?
        errors.add(:choose_your_npq, :invalid)
      end
    end
  end
end

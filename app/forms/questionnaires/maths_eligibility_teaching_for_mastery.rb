module Questionnaires
  class MathsEligibilityTeachingForMastery < Base
    include Helpers::Institution

    QUESTION_NAME = :maths_eligibility_teaching_for_mastery

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :maths_eligibility_teaching_for_mastery,
          options:,
          style_options: { legend: { size: "m", tag: "h2" } },
        ),
      ]
    end

    def options
      [
        build_option_struct(value: "yes", link_errors: true),
        build_option_struct(value: "no", hint: I18n.t("helpers.hint.registration_wizard.maths_eligibility_teaching_for_mastery_hint")),
      ]
    end

    def next_step
      if maths_eligibility_teaching_for_mastery == "yes"
        wizard.store["maths_understanding"] = true
        if !wizard.query_store.teacher_catchment_england? || wizard.query_store.kind_of_nursery_private?
          :ineligible_for_funding
        elsif wizard.query_store.works_in_school? && !state_funded_school?
          :ineligible_for_funding
        elsif wizard.query_store.works_in_another_setting?
          case funding_eligibility_calculator.funding_eligiblity_status_code
          when FundingEligibility::NO_INSTITUTION, FundingEligibility::FUNDED_ELIGIBILITY_RESULT, FundingEligibility::REFERRED_BY_RETURN_TO_TEACHING_ADVISER
            :possible_funding
          else
            :ineligible_for_funding
          end
        elsif wizard.query_store.referred_by_return_to_teaching_adviser?
          :possible_funding
        else
          :funding_eligibility_maths
        end
      else
        wizard.store["maths_understanding"] = false
        :maths_understanding_of_approach
      end
    end

    def previous_step
      :choose_your_npq
    end

  private

    def funding_eligibility_calculator
      @funding_eligibility_calculator ||= FundingEligibility.new(
        course:,
        institution: school,
        approved_itt_provider: approved_itt_provider?,
        lead_mentor: lead_mentor_for_accredited_itt_provider?,
        inside_catchment: inside_catchment?,
        trn:,
        get_an_identity_id:,
        query_store:,
      )
    end

    def state_funded_school?
      school.eligible_establishment?
    end

    def institution_identifier
      wizard.store["institution_identifier"]
    end

    def school
      institution(source: institution_identifier)
    end

    delegate :inside_catchment?, :approved_itt_provider?, :lead_mentor_for_accredited_itt_provider?, :trn,
             :get_an_identity_id, :course, to: :query_store
  end
end

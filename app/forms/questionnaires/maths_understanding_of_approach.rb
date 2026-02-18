module Questionnaires
  class MathsUnderstandingOfApproach < Base
    include Helpers::Institution

    QUESTION_NAME = :maths_understanding_of_approach

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :maths_understanding_of_approach,
          options:,
          style_options: { legend: { size: "xl", tag: "h" } },
        ),
      ]
    end

    def options
      [
        build_option_struct(value: "taken_a_similar_course", link_errors: true),
        build_option_struct(value: "another_way", hint: I18n.t("helpers.hint.registration_wizard.maths_understanding_of_approach_hint")),
        build_option_struct(value: "cannot_show", link_errors: true, divider: true),
      ]
    end

    def next_step
      if maths_understanding_of_approach == "cannot_show"
        :maths_cannot_register
      elsif funding_eligibility_calculator.funded?
        :funding_eligibility_maths
      elsif funding_eligibility_calculator.subject_to_review?
        :possible_funding
      else
        :ineligible_for_funding
      end
    end

    def previous_step
      :maths_eligibility_teaching_for_mastery
    end

  private

    delegate :inside_catchment?, :approved_itt_provider?, :lead_mentor_for_accredited_itt_provider?, :trn,
             :get_an_identity_id, :course, to: :query_store

    def funding_eligibility_calculator
      @funding_eligibility_calculator ||= FundingEligibility.new_from_query_store(
        course:,
        institution:,
        approved_itt_provider: approved_itt_provider?,
        lead_mentor: lead_mentor_for_accredited_itt_provider?,
        inside_catchment: inside_catchment?,
        trn:,
        get_an_identity_id:,
        query_store:,
      )
    end
  end
end

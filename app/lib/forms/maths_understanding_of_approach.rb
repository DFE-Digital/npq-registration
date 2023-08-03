module Forms
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
        Forms::QuestionTypes::RadioButtonGroup.new(
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
      if %w[taken_a_similar_course another_way].include?(maths_understanding_of_approach)
        :funding_eligibility_maths
      else
        :maths_cannot_register
      end
    end

    def previous_step
      :maths_eligibility_teaching_for_mastery
    end
  end
end

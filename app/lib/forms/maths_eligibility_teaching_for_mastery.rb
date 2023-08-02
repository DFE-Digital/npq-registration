module Forms
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
        Forms::QuestionTypes::RadioButtonGroup.new(
          name: :maths_eligibility_teaching_for_mastery,
          options:,
          style_options: { legend: { size: "m", tag: "h1" } },
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
        :possible_funding
      else
        :choose_your_npq
      end
    end

    def previous_step
      :choose_your_npq
    end
  end
end

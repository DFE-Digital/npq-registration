module Questionnaires
  class CourseStartDate < Base
    include Helpers::Institution

    QUESTION_NAME = :course_start_date

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :course_start_date,
          options:,
          style_options: { legend: { size: "m", tag: "h1" } },
        ),
      ]
    end

    def options
      [
        build_option_struct(value: "yes", link_errors: true, hint: I18n.t("helpers.hint.registration_wizard.course_start_date_hint")),
        build_option_struct(value: "no"),
      ]
    end

    def next_step
      if course_start_date == "yes"
        wizard.store["course_start"] = "February 2024"
        :provider_check
      else
        :cannot_register_yet
      end
    end

    def previous_step
      :start
    end
  end
end

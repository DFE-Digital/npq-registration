module Questionnaires
  class CourseStartDate < Base
    class Form < QuestionTypes::RadioButtonGroup
      include ApplicationHelper
      def type
        "radio_button_group"
      end

      def question_text
        "Do you want to start a course before #{application_course_start_date}?"
      end
    end

    include Helpers::Institution
    include ApplicationHelper

    QUESTION_NAME = :course_start_date

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        Form.new(
          name: :course_start_date,
          options:,
          style_options: { legend: { size: "m", tag: "h2" } },
        ),
      ]
    end

    def options
      [
        build_option_struct(value: "yes", link_errors: true, hint: I18n.t("helpers.hint.registration_wizard.course_start_date_hint")),
        build_option_struct(value: "no"),
      ]
    end

    def requirements_met?
      query_store.current_user.present?
    end

    def next_step
      if course_start_date == "yes"
        wizard.store["course_start"] = "Before #{application_course_start_date}"
        wizard.current_user.update!(notify_user_for_future_reg: false)
        :provider_check
      else
        wizard.current_user.update!(notify_user_for_future_reg: true)
        :cannot_register_yet
      end
    end

    def previous_step
      :start
    end
  end
end

module Questionnaires
  class CourseStartDate < Base
    include ApplicationHelper

    QUESTION_NAME = :course_start_cohort

    OPTIONS = {
      "2026b" => { label: "Yes",
                   cohort_description: "Autumn 2026" },
      "2026a" => { label: "No, I already started in Spring",
                   hint: "DfE scholarship funding is not available",
                   cohort_description: "Spring 2026" },
    }.freeze

    attribute QUESTION_NAME

    validates QUESTION_NAME, presence: true, inclusion: { in: OPTIONS.keys }
    validate :cohort_exists, if: -> { course_start_cohort.present? }

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :course_start_cohort,
          options:,
        ),
      ]
    end

    def options
      OPTIONS.map do |cohort_identifier, label_options|
        build_option_struct(value: cohort_identifier, label: label_options[:label], hint: label_options[:hint])
      end
    end

    def requirements_met?
      query_store.current_user
    end

    def next_step
      if Cohort.find_by(identifier: course_start_cohort).funded?
        :check_funding
      else
        :choose_your_npq
      end
    end

    def previous_step
      :start
    end

    def return_to_regular_flow_on_change?
      true
    end

  private

    def cohort_exists
      return if Cohort.find_by(identifier: course_start_cohort)

      errors.add(QUESTION_NAME, :invalid)
      Sentry.capture_message("Cohort selected by user does not exist: #{course_start_cohort}")
    end
  end
end

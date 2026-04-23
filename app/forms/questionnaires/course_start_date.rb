module Questionnaires
  class CourseStartDate < Base
    include ApplicationHelper

    QUESTION_NAME = :course_start_cohort

    OPTIONS = {
      "2026a" => "Spring 2026",
      "2026b" => "Autumn 2026",
    }.freeze

    attribute QUESTION_NAME

    validates QUESTION_NAME, presence: true, inclusion: { in: OPTIONS.keys }
    validate :cohort_exists

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
      OPTIONS.map { |value, label| build_option_struct(value:, label:) }
    end

    def requirements_met?
      query_store.current_user
    end

    def next_step
      :provider_check
    end

    def previous_step
      :start
    end

  private

    def cohort_exists
      cohort = Cohort.find_by(identifier: public_send(QUESTION_NAME))
      errors.add(QUESTION_NAME, :invalid) unless cohort
    end
  end
end

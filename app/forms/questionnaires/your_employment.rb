module Questionnaires
  class YourEmployment < Base
    QUESTION_NAME = :employment_type

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: QUESTION_NAME,
          options:,
        ),
      ]
    end

    def options
      Application.employment_types.keys
                 .reject { |v| v == "other" } # Other is handled on the previous page
                 .each_with_index.map do |value, index|
        build_option_struct(
          value:,
          link_errors: index.zero?,
        )
      end
    end

    def next_step
      case employment_type
      when Application.employment_types[:lead_mentor_for_accredited_itt_provider]
        :itt_provider
      when Application.employment_types[:hospital_school],
        Application.employment_types[:young_offender_institution]
        :your_employer
      else
        :your_role
      end
    end

    def previous_step
      :work_setting
    end
  end
end

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
      [
        build_option_struct(value: "local_authority_virtual_school", link_errors: true),
        build_option_struct(value: "hospital_school"),
        build_option_struct(value: "young_offender_institution"),
        build_option_struct(value: "local_authority_supply_teacher"),
        build_option_struct(value: "lead_mentor_for_accredited_itt_provider"),
      ].freeze
    end

    def next_step
      case employment_type
      when "lead_mentor_for_accredited_itt_provider"
        :itt_provider
      when "hospital_school", "young_offender_institution"
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

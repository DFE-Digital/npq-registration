module Questionnaires
  class CheckFunding < Base
    QUESTION_NAME = :check_funding

    OPTIONS = {
      "yes" => "Check funding",
      "no" => "Continue without DfE funding",
    }.freeze

    attribute QUESTION_NAME

    validates QUESTION_NAME, presence: true, inclusion: { in: OPTIONS.keys }

    def self.permitted_params
      [QUESTION_NAME]
    end

    def options
      OPTIONS.map do |value, label|
        build_option_struct(value:, label:)
      end
    end

    def previous_step
      :course_start_date
    end

    def next_step
      if check_funding == "yes"
        :teacher_catchment
      else
        :choose_your_npq
      end
    end
  end
end

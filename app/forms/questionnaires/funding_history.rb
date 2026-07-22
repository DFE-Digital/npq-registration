module Questionnaires
  class FundingHistory < Base
    QUESTION_NAME = :declared_previous_funding

    OPTIONS = {
      "yes" => "Yes",
      "no" => "No",
    }.freeze

    attribute QUESTION_NAME

    validates QUESTION_NAME, presence: true, inclusion: { in: OPTIONS.keys }

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
      OPTIONS.map do |value, label|
        build_option_struct(value:, label:)
      end
    end

    def previous_step
      :choose_your_npq
    end

    def next_step
      if declared_previous_funding == "yes"
        :ineligible_for_funding_previously_funded
      else
        :work_setting
      end
    end
  end
end

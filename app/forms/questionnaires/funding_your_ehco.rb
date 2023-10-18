module Questionnaires
  class FundingYourEhco < Base
    VALID_FUNDING_OPTIONS = %w[school trust self another].freeze

    attr_accessor :ehco_funding_choice

    validates :ehco_funding_choice, presence: true, inclusion: { in: VALID_FUNDING_OPTIONS }

    def self.permitted_params
      %i[
        ehco_funding_choice
      ]
    end

    def next_step
      :choose_your_provider
    end

    def previous_step
      "ehco_funding_not_available"
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :ehco_funding_choice,
          options:,
        ),
      ]
    end

    def options
      [
        build_option_struct(value: "school", link_errors: true),
        build_option_struct(value: "trust"),
        build_option_struct(value: "self"),
        build_option_struct(value: "another"),
      ].freeze
    end
  end
end

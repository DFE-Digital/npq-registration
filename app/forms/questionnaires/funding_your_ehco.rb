module Questionnaires
  class FundingYourEhco < Base
    VALID_FUNDING_OPTIONS = %w[school trust self another].freeze

    attribute :ehco_funding_choice

    validates :ehco_funding_choice, presence: true, inclusion: { in: VALID_FUNDING_OPTIONS }

    def self.permitted_params
      %i[
        ehco_funding_choice
      ]
    end

    def previous_step
      if shown_ineligible_step_during_journey?
        :work_setting
      else
        :ineligible_for_funding
      end
    end

    def next_step
      :choose_your_provider
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
      # compared to the funding_your_npq step - here the 'trust' option is always shown
      [
        build_option_struct(value: "school", link_errors: true),
        build_option_struct(value: "trust"),
        build_option_struct(value: "self"),
        build_option_struct(value: "another"),
      ].freeze
    end
  end
end

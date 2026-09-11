module Questionnaires
  class FundingYourNpq < Base
    VALID_FUNDING_OPTIONS = %w[school trust self another employer].freeze

    attribute :funding

    validates :funding, presence: true, inclusion: { in: VALID_FUNDING_OPTIONS, allow_blank: true }

    def self.permitted_params
      %i[
        funding
      ]
    end

    def previous_step
      if query_store.declared_previous_funding? || query_store.asked_to_continue_without_checking_funding? || query_store.declared_not_working_in_england?
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
          name: :funding,
          options:,
        ),
      ]
    end

    def options
      [
        build_option_struct(value: "school", link_errors: true),
        (build_option_struct(value: "trust") if works_in_school? && inside_catchment?),
        build_option_struct(value: "self"),
        build_option_struct(value: "another"),
      ].compact.freeze
    end

    delegate :works_in_school?, :inside_catchment?, to: :query_store
  end
end

module Forms
  class FundingYourNpq < Base
    VALID_FUNDING_OPTIONS = %w[school trust self another employer].freeze

    attr_accessor :funding

    validates :funding, presence: true, inclusion: { in: VALID_FUNDING_OPTIONS }

    def self.permitted_params
      %i[
        funding
      ]
    end

    def next_step
      :choose_your_provider
    end

    def previous_step
      :ineligible_for_funding
    end

    def course
      @course ||= wizard.query_store.course
    end

    def question
      Forms::QuestionTypes::RadioButtonGroup.new(
        name: :funding,
        options:,
      )
    end

    def options
      [
        build_option_struct(value: "school", link_errors: true),
        (build_option_struct(value: "trust") if works_in_school? && inside_catchment?),
        build_option_struct(value: "self"),
        build_option_struct(value: "another"),
      ].compact.freeze
    end

    delegate :query_store, to: :wizard
    delegate :works_in_school?, :inside_catchment?, to: :query_store
  end
end

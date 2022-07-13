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
      @course ||= Course.find(wizard.store["course_id"])
    end

    def options
      [
        option("school", "My workplace is covering the cost", link_errors: true),
        (option("trust", "My trust is paying") if works_in_school? && inside_catchment?),
        option("self", "I am paying"),
        option("another", "My NPQ is being paid in another way", "For example, I am sharing the costs with my workplace"),
      ].compact.freeze
    end

    def title
      "How is your course being paid for?"
    end

  private

    def option(value, text, description = nil, link_errors: false)
      OpenStruct.new(value:, text:, description:, link_errors:)
    end

    delegate :query_store, to: :wizard
    delegate :works_in_school?, :inside_catchment?, to: :query_store
  end
end

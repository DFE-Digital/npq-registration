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
        (option("school", "My school or college is covering the cost", link_errors: true) if works_in_school?),
        (option("trust", "My trust is paying") if works_in_school? && inside_catchment?),
        (option("employer", "My employer is paying") if !inside_catchment? || !works_in_school?),
        option("self", "I am paying"),
        option("another", "My NPQ is being paid in another way", "For example, I am sharing the costs with my school or college"),
      ].compact.freeze
    end

    def title
      if inside_catchment? && works_in_school?
        "Funding"
      else
        "How is your course being paid for?"
      end
    end

  private

    def option(value, text, description = nil, link_errors: false)
      OpenStruct.new(
        value: value,
        text: text,
        description: description,
        link_errors: link_errors,
      )
    end

    def works_in_school?
      wizard.query_store.works_in_school?
    end

    def inside_catchment?
      wizard.query_store.inside_catchment?
    end
  end
end

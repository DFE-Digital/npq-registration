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
      :choose_your_npq
    end

    def course
      @course ||= Course.find(wizard.store["course_id"])
    end

    def options
      if wizard.query_store.inside_catchment?
        england_options
      else
        outside_england_options
      end
    end

    def title
      if wizard.query_store.inside_catchment?
        "Funding"
      else
        "How is your course being paid for?"
      end
    end

  private

    def england_options
      [
        OpenStruct.new(value: "school",
                       text: "My school or college is covering the cost",
                       link_errors: true),
        OpenStruct.new(value: "trust",
                       text: "My trust is paying",
                       link_errors: false),
        OpenStruct.new(value: "self",
                       text: "I am paying",
                       link_errors: false),
        OpenStruct.new(value: "another",
                       text: "My NPQ is being paid in another way",
                       description: "For example, I am sharing the costs with my school or college",
                       link_errors: false),
      ].freeze
    end

    def outside_england_options
      [
        OpenStruct.new(value: "school",
                       text: "My school or college is covering the cost",
                       link_errors: true),
        OpenStruct.new(value: "employer",
                       text: "My employer is paying",
                       link_errors: false),
        OpenStruct.new(value: "self",
                       text: "I am paying",
                       link_errors: false),
        OpenStruct.new(value: "another",
                       text: "My NPQ is being paid in another way",
                       description: "For example, I am sharing the costs with my school or college",
                       link_errors: false),
      ].freeze
    end
  end
end

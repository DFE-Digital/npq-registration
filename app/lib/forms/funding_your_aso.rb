module Forms
  class FundingYourAso < Base
    VALID_FUNDING_OPTIONS = %w[school trust self another].freeze

    attr_accessor :aso_funding_choice

    validates :aso_funding_choice, presence: true, inclusion: { in: VALID_FUNDING_OPTIONS }

    def self.permitted_params
      %i[
        aso_funding_choice
      ]
    end

    def next_step
      :choose_your_provider
    end

    def previous_step
      :aso_funding_not_available
    end

    def options
      [
        OpenStruct.new(value: "school",
                       text: "My workplace is covering the cost",
                       link_errors: true),
        OpenStruct.new(value: "trust",
                       text: "My trust is paying",
                       link_errors: false),
        OpenStruct.new(value: "self",
                       text: "I am paying",
                       link_errors: false),
        OpenStruct.new(value: "another",
                       text: "The Early Headship Coaching Offer is being paid in another way",
                       hint: "For example, I am sharing the costs with my workplace",
                       link_errors: false),
      ].freeze
    end
  end
end

module Forms
  class FundingYourNpq < Base
    VALID_FUNDING_OPTIONS = %w[school trust self another].freeze

    attr_accessor :funding

    validates :funding, presence: true, inclusion: { in: VALID_FUNDING_OPTIONS }

    def self.permitted_params
      %i[
        funding
      ]
    end

    def next_step
      :check_answers
    end

    def previous_step
      :choose_school
    end

    def course
      @course ||= Course.find(wizard.store["course_id"])
    end

    def options
      [
        OpenStruct.new(value: "school",
                       text: "My school is paying",
                       link_errors: true),
        OpenStruct.new(value: "trust",
                       text: "My trust is paying",
                       link_errors: false),
        OpenStruct.new(value: "self",
                       text: "I am paying",
                       link_errors: false),
        OpenStruct.new(value: "another",
                       text: "My NPQ is being paid in another way",
                       description: "For example, I am sharing the costs with my school",
                       link_errors: false),
      ].freeze
    end
  end
end

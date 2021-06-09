module Forms
  class HeadteacherDuration < Base
    VALID_HEADERTEACHER_OVER_TWO_YEARS_OPTIONS = %w[yes no].freeze

    attr_accessor :headerteacher_over_two_years

    validates :headerteacher_over_two_years, presence: true, inclusion: { in: VALID_HEADERTEACHER_OVER_TWO_YEARS_OPTIONS }

    def self.permitted_params
      %i[
        headerteacher_over_two_years
      ]
    end

    def next_step
      :choose_your_provider
    end

    def previous_step
      :choose_your_npq
    end

    def options
      [
        OpenStruct.new(value: "yes",
                       text: "Yes, I have been a headteacher for two years or more",
                       link_errors: true),
        OpenStruct.new(value: "no",
                       text: "No, I’m not a headteacher or have been a headteacher for less than two years",
                       link_errors: false),
      ]
    end
  end
end

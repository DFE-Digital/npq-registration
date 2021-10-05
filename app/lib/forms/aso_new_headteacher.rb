module Forms
  class AsoNewHeadteacher < Base
    VALID_ASO_NEW_HEADTEACHER_OPTIONS = %w[yes no].freeze

    include Helpers::Institution

    attr_accessor :aso_new_headteacher

    validates :aso_new_headteacher, presence: true, inclusion: { in: VALID_ASO_NEW_HEADTEACHER_OPTIONS }

    def self.permitted_params
      %i[
        aso_new_headteacher
      ]
    end

    def next_step
      if aso_new_headteacher == "no"
        :aso_funding_not_available
      else
        :aso_possible_funding
      end
    end

    def previous_step
      :aso_headteacher
    end

    def options
      options_array.each_with_index.map do |option, index|
        OpenStruct.new(value: option[:value],
                       text: option[:text],
                       link_errors: index.zero?)
      end
    end

  private

    def options_array
      [
        {
          text: "Yes, I am in my first 2 years of a headship",
          value: "yes",
        },
        {
          text: "No",
          value: "no",
        },
      ]
    end
  end
end

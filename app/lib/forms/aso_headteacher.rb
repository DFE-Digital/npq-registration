module Forms
  class AsoHeadteacher < Base
    VALID_ASO_HEADTEACHER_OPTIONS = %w[yes no].freeze

    include Helpers::Institution

    attr_accessor :aso_headteacher

    validates :aso_headteacher, presence: true, inclusion: { in: VALID_ASO_HEADTEACHER_OPTIONS }

    def self.permitted_params
      %i[
        aso_headteacher
      ]
    end

    def next_step
      if aso_headteacher == "no"
        :aso_funding_not_available
      else
        :aso_new_headteacher
      end
    end

    def previous_step
      :npqh_status
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
          text: "Yes",
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

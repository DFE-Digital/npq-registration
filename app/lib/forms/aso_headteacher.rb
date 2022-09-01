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

    def question
      Forms::QuestionTypes::RadioButtonGroup.new(name: :aso_headteacher, options:)
    end

    def options
      [
        build_option_struct(value: "yes", link_errors: true),
        build_option_struct(value: "no"),
      ]
    end
  end
end

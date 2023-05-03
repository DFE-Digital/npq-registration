module Forms
  class EhcoHeadteacher < Base
    VALID_EHCO_HEADTEACHER_OPTIONS = %w[yes no].freeze

    include Helpers::Institution

    attr_accessor :ehco_headteacher

    validates :ehco_headteacher, presence: true, inclusion: { in: VALID_EHCO_HEADTEACHER_OPTIONS }

    def self.permitted_params
      %i[
        ehco_headteacher
      ]
    end

    def next_step
      if ehco_headteacher == "no"
        :ehco_funding_not_available
      else
        :ehco_new_headteacher
      end
    end

    def previous_step
      :npqh_status
    end

    def question
      Forms::QuestionTypes::RadioButtonGroup.new(name: :ehco_headteacher, options:)
    end

    def options
      [
        build_option_struct(value: "yes", link_errors: true),
        build_option_struct(value: "no"),
      ]
    end
  end
end

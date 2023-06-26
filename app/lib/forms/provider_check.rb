module Forms
  class ProviderCheck < Base
    VALID_CHOSEN_PROVIDER_OPTIONS = %w[yes no].freeze

    QUESTION_NAME = :chosen_provider

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true, inclusion: { in: VALID_CHOSEN_PROVIDER_OPTIONS }

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        Forms::QuestionTypes::RadioButtonGroup.new(
          name: :chosen_provider,
          options:,
          style_options: { legend: { size: "xl", tag: "h1" } },
        ),
      ]
    end

    def options
      [
        build_option_struct(value: "yes", label: "Yes", link_errors: true),
        build_option_struct(value: "no", label: "No"),
      ]
    end

    def requirements_met?
      query_store.current_user.present?
    end

    def next_step
      case chosen_provider
      when "yes"
        :teacher_catchment
      when "no"
        :choose_an_npq_and_provider
      end
    end

    def previous_step
      :start
    end
  end
end

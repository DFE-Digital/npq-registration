module Forms
  class ProviderCheck < Base
    VALID_CHOSEN_PROVIDER_OPTIONS = %w[yes no].freeze

    QUESTION_NAME = :chosen_provider

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true, inclusion: { in: VALID_CHOSEN_PROVIDER_OPTIONS }

    def self.permitted_params
      [QUESTION_NAME]
    end

    def question
      Forms::QuestionTypes::RadioButtonGroup.new(
        name: :chosen_provider,
        options:,
        style_options: { legend: { size: "m", tag: "h1" } },
      )
    end

    def options
      [
        build_option_struct(value: "yes", label: "Yes", link_errors: true),
        build_option_struct(value: "no", label: "No"),
      ]
    end

    # Required since this is the first question
    # If it wasn't overridden it would check if any previous questions were answered
    # and since there aren't any it would assume the user was trying to skip questions
    # and redirect them to the start page
    # Only overridden when this is the first question, which is now when the GAI pilot is off
    # for the current user
    def requirements_met?
      return true unless wizard.tra_get_an_identity_omniauth_integration_active?

      super
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
      if wizard.tra_get_an_identity_omniauth_integration_active?
        :get_an_identity
      else
        :start
      end
    end
  end
end

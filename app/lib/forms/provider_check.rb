module Forms
  class ProviderCheck < Base
    VALID_CHOSEN_PROVIDER_OPTIONS = %w[yes no].freeze

    attr_accessor :chosen_provider

    validates :chosen_provider, presence: true, inclusion: { in: VALID_CHOSEN_PROVIDER_OPTIONS }

    def self.permitted_params
      %i[
        chosen_provider
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

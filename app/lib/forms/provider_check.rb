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

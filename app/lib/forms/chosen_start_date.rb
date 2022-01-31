module Forms
  class ChosenStartDate < Base
    VALID_CHOSEN_START_DATE_OPTIONS = %w[yes no].freeze

    attr_accessor :chosen_start_date

    validates :chosen_start_date, presence: true, inclusion: { in: VALID_CHOSEN_START_DATE_OPTIONS }

    def self.permitted_params
      %i[
        chosen_start_date
      ]
    end

    def requirements_met?
      true
    end

    def next_step
      case chosen_start_date
      when "yes"
        :provider_check
      when "no"
        :notification_option
      end
    end

    def previous_step
      :start
    end
  end
end

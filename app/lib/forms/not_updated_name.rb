module Forms
  class NotUpdatedName < Base
    VALID_NAME_NOT_UPDATED_ACTION_OPTIONS = %w[change_dqt_name use_old_name].freeze

    attr_accessor :name_not_updated_action

    validates :name_not_updated_action,
              presence: true,
              inclusion: { in: VALID_NAME_NOT_UPDATED_ACTION_OPTIONS }

    def self.permitted_params
      [:name_not_updated_action]
    end

    def next_step
      case name_not_updated_action
      when "change_dqt_name"
        :change_dqt
      when "use_old_name"
        :contact_details
      end
    end

    def previous_step
      :updated_name
    end
  end
end

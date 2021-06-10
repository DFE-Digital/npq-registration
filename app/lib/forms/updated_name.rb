module Forms
  class UpdatedName < Base
    VALID_UPDATED_NAME_OPTIONS = %w[yes no not-sure].freeze

    attr_accessor :updated_name

    validates :updated_name, presence: true, inclusion: { in: VALID_UPDATED_NAME_OPTIONS }

    def self.permitted_params
      %i[
        updated_name
      ]
    end

    def next_step
      case updated_name
      when "yes"
        :contact_details
      when "no"
        :not_updated_name
      when "not-sure"
        :not_sure_updated_name
      end
    end

    def previous_step
      :name_changes
    end
  end
end

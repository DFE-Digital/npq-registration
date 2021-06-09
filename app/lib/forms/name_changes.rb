module Forms
  class NameChanges < Base
    VALID_CHANGED_NAME_OPTIONS = %w[yes no].freeze

    attr_accessor :changed_name

    validates :changed_name, presence: true, inclusion: { in: VALID_CHANGED_NAME_OPTIONS }

    def self.permitted_params
      %i[
        changed_name
      ]
    end

    def next_step
      case changed_name
      when "yes"
        :updated_name
      when "no"
        :contact_details
      end
    end

    def previous_step
      :teacher_reference_number
    end
  end
end

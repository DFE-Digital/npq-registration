module Forms
  class NameChanges
    include ActiveModel::Model

    attr_accessor :wizard, :changed_name

    validates :changed_name, presence: true

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

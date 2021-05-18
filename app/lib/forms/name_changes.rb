module Forms
  class NameChanges
    include ActiveModel::Model

    attr_accessor :changed_name

    validates :changed_name, presence: true

    def self.permitted_params
      %i[
        changed_name
      ]
    end

    def next_step
      :contact_details
    end

    def previous_step
      :teacher_reference_number
    end
  end
end

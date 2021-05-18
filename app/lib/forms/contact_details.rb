module Forms
  class ContactDetails
    include ActiveModel::Model

    attr_accessor :email

    validates :email, presence: true, email: true

    def self.permitted_params
      %i[
        email
      ]
    end

    def next_step
      :complete
    end

    def previous_step
      :teacher_reference_number
    end
  end
end

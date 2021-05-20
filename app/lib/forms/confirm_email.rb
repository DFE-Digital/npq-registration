module Forms
  class ConfirmEmail
    include ActiveModel::Model

    attr_accessor :wizard, :confirmation_code

    validates :confirmation_code, presence: true, length: { is: 6 }

    def self.permitted_params
      [
        :confirmation_code,
      ]
    end

    def previous_step
      :contact_details
    end
  end
end

module Forms
  class ConfirmEmail
    include ActiveModel::Model

    attr_accessor :wizard

    def self.permitted_params
      []
    end

    def previous_step
      :contact_details
    end
  end
end

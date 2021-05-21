module Forms
  class SelectDeliveryPartner < Base
    def previous_step
      :delivery_partner
    end

    def next_step
      :check_answers
    end
  end
end

module Forms
  class DeliveryPartner < Base
    def previous_step
      :choose_your_provider
    end
  end
end

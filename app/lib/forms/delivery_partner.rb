module Forms
  class DeliveryPartner < Base
    VALID_DELIVERY_PARTNER_KNOWLEDGE_OPTIONS = %w[yes no].freeze

    attr_accessor :delivery_partner_knowledge

    validates :delivery_partner_knowledge, presence: true, inclusion: { in: VALID_DELIVERY_PARTNER_KNOWLEDGE_OPTIONS }

    def self.permitted_params
      %i[
        delivery_partner_knowledge
      ]
    end

    def next_step
      :select_delivery_partner
    end

    def previous_step
      :choose_your_provider
    end

    def lead_provider
      @lead_provider ||= LeadProvider.find(wizard.store["lead_provider_id"])
    end
  end
end

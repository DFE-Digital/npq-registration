module Forms
  class ChooseYourProvider < Base
    attr_accessor :lead_provider_id

    validates :lead_provider_id, presence: true
    validate :validate_lead_provider_exists

    def self.permitted_params
      %i[
        lead_provider_id
      ]
    end

    def next_step
      :delivery_partner
    end

    def previous_step
      :choose_your_npq
    end

    def options
      LeadProvider.all.each_with_index.map do |provider, index|
        OpenStruct.new(value: provider.id,
                       text: provider.name,
                       link_errors: index.zero?)
      end
    end

  private

    def lead_provider
      LeadProvider.find_by(id: lead_provider_id)
    end

    def validate_lead_provider_exists
      if lead_provider.blank?
        errors.add(:lead_provider_id, :invalid)
      end
    end
  end
end

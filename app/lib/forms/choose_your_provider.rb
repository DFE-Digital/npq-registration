module Forms
  class ChooseYourProvider < Base
    attr_accessor :provider

    validates :provider, presence: true

    def self.permitted_params
      %i[
        provider
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
  end
end

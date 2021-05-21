module Forms
  class ChooseYourProvider < Base
    OPTIONS = [
      "Ambition Institute",
      "Best Practice Network",
      "Church of England",
      "Education Development Trust",
      "Harris Federation",
      "Leadership Learning South East",
      "Teacher Development Trust",
      "Teach First",
      "UCL Institute of Education",
    ].each_with_index.map { |option, index|
      OpenStruct.new(value: option,
                     text: option,
                     link_errors: index.zero?)
    }.freeze

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
      OPTIONS
    end
  end
end

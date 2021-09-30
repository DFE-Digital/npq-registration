module Forms
  class AsoFundingNotAvailable < Base
    attr_accessor :aso_funding

    validates :aso_funding, presence: true

    def self.permitted_params
      %i[
        aso_funding
      ]
    end

    def previous_step
      if wizard.store["aso_headteacher"] == "yes"
        :aso_new_headteacher
      else
        :aso_headteacher
      end
    end

    def next_step
      if aso_funding == "no"
        :aso_funding_contact
      else
        :funding_your_aso
      end
    end

    def options
      [
        OpenStruct.new(value: "yes",
                       text: "Yes, I will pay another way",
                       link_errors: true),
        OpenStruct.new(value: "no",
                       text: "No",
                       link_errors: false),
      ]
    end
  end
end

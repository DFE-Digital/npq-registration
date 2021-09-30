module Forms
  class AsoFundingContact < Base
    def previous_step
      :aso_funding_not_available
    end
  end
end

module Forms
  class AsoPreviouslyFunded < Base
    def previous_step
      if wizard.store["aso_headteacher"] == "yes"
        :aso_new_headteacher
      else
        :aso_headteacher
      end
    end

    def next_step
      :funding_your_aso
    end
  end
end

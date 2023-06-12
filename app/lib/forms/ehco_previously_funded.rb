module Forms
  class EhcoPreviouslyFunded < Base
    def previous_step
      if wizard.store["ehco_headteacher"] == "yes"
        :ehco_new_headteacher
      else
        :ehco_headteacher
      end
    end

    def next_step
      :funding_your_ehco
    end

    delegate :lead_provider, to: :query_store
  end
end

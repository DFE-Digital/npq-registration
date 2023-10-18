module Questionnaires
  class EhcoFundingNotAvailable < Base
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
  end
end

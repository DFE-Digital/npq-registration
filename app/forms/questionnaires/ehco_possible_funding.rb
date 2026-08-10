module Questionnaires
  class EhcoPossibleFunding < Base
    def previous_step
      :ehco_new_headteacher
    end

    def next_step
      :choose_your_provider
    end
  end
end

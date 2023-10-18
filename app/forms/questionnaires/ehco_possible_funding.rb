module Questionnaires
  class EhcoPossibleFunding < Base
    def next_step
      :choose_your_provider
    end

    def previous_step
      :ehco_new_headteacher
    end

    def course
      @course ||= wizard.query_store.course
    end
  end
end

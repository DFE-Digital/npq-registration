module Questionnaires
  class EhcoUnavailable < Base
    def previous_step
      :npqh_status
    end

    def next_step
      # you cannot proceed any further from this step
    end
  end
end

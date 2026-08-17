module Questionnaires
  class Start < Base
    def requirements_met?
      true
    end

    def next_step
      :course_start_date
    end
  end
end

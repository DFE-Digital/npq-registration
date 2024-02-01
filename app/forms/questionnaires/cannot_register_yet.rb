module Questionnaires
  class CannotRegisterYet < Base
    def previous_step
      :course_start_date
    end

    def next_step; end
  end
end

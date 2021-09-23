module Forms
  class PossibleFunding < Base
    def next_step
      :check_answers
    end

    def previous_step
      :choose_school
    end

    def course
      @course ||= Course.find(wizard.store["course_id"])
    end
  end
end

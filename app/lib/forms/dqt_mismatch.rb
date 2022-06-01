module Forms
  class DqtMismatch < Base
    def previous_step
      :qualified_teacher_check
    end

    def next_step
      if changing_answer?
        :check_answers
      elsif wizard.query_store.works_in_school?
        if wizard.query_store.inside_catchment?
          :find_school
        else
          :choose_your_npq
        end
      else
        :work_in_childcare
      end
    end
  end
end

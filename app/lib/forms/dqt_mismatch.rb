module Forms
  class DqtMismatch < Base
    def previous_step
      :qualified_teacher_check
    end

    def next_step
      if changing_answer?
        :check_answers
      elsif wizard.query_store.inside_catchment? && wizard.query_store.works_in_school?
        :find_school
      else
        :work_in_childcare
      end
    end
  end
end

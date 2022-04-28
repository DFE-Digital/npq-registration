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
      elsif wizard.query_store.inside_catchment? && wizard.query_store.works_in_childcare?
        :find_childcare_provider
      else
        :choose_your_npq
      end
    end
  end
end

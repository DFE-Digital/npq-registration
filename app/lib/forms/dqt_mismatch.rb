module Forms
  class DqtMismatch < Base
    def previous_step
      :qualified_teacher_check
    end

    def next_step
      return :check_answers if changing_answer?

      if wizard.query_store.inside_catchment?
        return :find_school if wizard.query_store.works_in_school?
        return :kind_of_nursery if wizard.query_store.works_in_childcare?

        return :your_employment
      end

      :choose_your_npq
    end
  end
end

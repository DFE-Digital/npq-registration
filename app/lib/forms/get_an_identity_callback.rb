module Forms
  class GetAnIdentityCallback < Base
    def skip_step?
      true
    end

    def next_step
      if wizard.query_store.inside_catchment?
        return :find_school if wizard.query_store.works_in_school?
        return :work_in_nursery if wizard.query_store.works_in_childcare?

        return :your_employment
      end

      :choose_your_npq
    end

    def previous_step
      :teacher_reference_number
    end
  end
end

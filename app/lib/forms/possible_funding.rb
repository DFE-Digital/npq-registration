module Forms
  class PossibleFunding < Base
    def next_step
      :choose_your_provider
    end

    def previous_step
      :choose_your_npq
    end

    def course
      @course ||= Course.find(wizard.store["course_id"])
    end

    def message_template
      return "private_childcare_provider" if wizard.query_store.works_in_private_childcare_provider?

      "school"
    end
  end
end

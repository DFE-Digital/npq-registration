module Forms
  class AsoPossibleFunding < Base
    def next_step
      :choose_your_provider
    end

    def previous_step
      :aso_new_headteacher
    end

    def course
      @course ||= Course.find(wizard.store["course_id"])
    end
  end
end

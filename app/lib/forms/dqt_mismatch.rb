module Forms
  class DqtMismatch < Base
    def previous_step
      :qualified_teacher_check
    end

    def next_step
      :choose_your_npq
    end
  end
end

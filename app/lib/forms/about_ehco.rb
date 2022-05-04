module Forms
  class AboutEhco < Base
    def previous_step
      :choose_your_npq
    end

    def next_step
      :npqh_status
    end
  end
end

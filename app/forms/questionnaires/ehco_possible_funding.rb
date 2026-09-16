module Questionnaires
  class EhcoPossibleFunding < Base
    def previous_step
      if query_store.lead_mentor_for_accredited_itt_provider?
        :itt_provider
      elsif query_store.works_in_another_setting?
        :your_employer
      elsif query_store.works_in_other?
        :referred_by_return_to_teaching_adviser
      elsif query_store.course.ehco?
        :ehco_new_headteacher
      end
    end

    def next_step
      :choose_your_provider
    end
  end
end

module Forms
  class WorkInChildcare < Base
    VALID_WORK_IN_CHILDCARE_OPTIONS = %w[yes no].freeze

    attr_accessor :works_in_childcare

    validates :works_in_childcare, presence: true, inclusion: { in: VALID_WORK_IN_CHILDCARE_OPTIONS }

    def self.permitted_params
      %i[works_in_childcare]
    end

    def return_to_regular_flow_on_change?
      true
    end

    def next_step
      if wizard.query_store.inside_catchment? && works_in_childcare?
        :work_in_nursery
      else
        :choose_your_npq
      end
    end

    def works_in_childcare?
      works_in_childcare == "yes"
    end

    def previous_step
      :qualified_teacher_check
    end
  end
end

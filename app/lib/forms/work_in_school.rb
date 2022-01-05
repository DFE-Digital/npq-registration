module Forms
  class WorkInSchool < Base
    VALID_WORK_IN_SCHOOL_OPTIONS = %w[yes no].freeze

    attr_accessor :works_in_school

    validates :works_in_school, presence: true, inclusion: { in: VALID_WORK_IN_SCHOOL_OPTIONS }

    def self.permitted_params
      %i[works_in_school]
    end

    def requirements_met?
      true
    end

    def next_step
      :teacher_reference_number
    end

    def previous_step
      :teacher_catchment
    end
  end
end

module Forms
  class SchoolNotInEngland < Base
    def previous_step
      :choose_school
    end

    def next_step; end
  end
end

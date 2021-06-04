module Forms
  class SchoolNotInEngland < Base
    def previous_step
      :choose_school
    end
  end
end

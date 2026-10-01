module Questionnaires
  class SchoolNotInEngland < Base
    def previous_step
      :work_setting
    end

    def next_step
      # you cannot proceed any further from this step
    end
  end
end

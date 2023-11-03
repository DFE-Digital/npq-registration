module Questionnaires
  class DontHaveTeacherReferenceNumber < Base
    def previous_step
      :teacher_reference_number
    end

    def next_step; end
  end
end

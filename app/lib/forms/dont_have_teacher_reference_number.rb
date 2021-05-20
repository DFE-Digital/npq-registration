module Forms
  class DontHaveTeacherReferenceNumber < Base
    def previous_step
      :teacher_reference_number
    end
  end
end

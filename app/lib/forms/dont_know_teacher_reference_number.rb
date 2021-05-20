module Forms
  class DontKnowTeacherReferenceNumber < Base
    def previous_step
      :teacher_reference_number
    end
  end
end

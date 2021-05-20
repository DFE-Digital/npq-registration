module Forms
  class QualifiedTeacherCheck < Base
    def self.permitted_params
      %i[
      ]
    end

    def next_step
    end

    def previous_step
      :confirm_email
    end
  end
end

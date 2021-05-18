module Forms
  class DontHaveTeacherReferenceNumber
    include ActiveModel::Model

    attr_accessor :wizard

    def self.permitted_params
      []
    end

    def previous_step
      :teacher_reference_number
    end
  end
end

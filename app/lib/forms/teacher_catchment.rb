module Forms
  class TeacherCatchment < Base
    attr_accessor :teacher_catchment

    validates :teacher_catchment, presence: true

    def self.permitted_params
      %i[
        teacher_catchment
      ]
    end

    def requirements_met?
      true
    end

    def next_step
      :provider_check
    end

    def previous_step
      :start
    end

    def options
      [
        OpenStruct.new(value: "yes",
                       text: "Yes",
                       link_errors: true),
        OpenStruct.new(value: "no_teach_elsewhere",
                       text: "No, I’m a teacher somewhere else",
                       link_errors: false),
        OpenStruct.new(value: "no_not_teacher",
                       text: "No, I’m not a teacher",
                       link_errors: false),
      ]
    end
  end
end

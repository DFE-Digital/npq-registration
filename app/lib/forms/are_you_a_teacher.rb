module Forms
  class AreYouATeacher < Base
    attr_accessor :teacher_status

    validates :teacher_status, presence: true

    def self.permitted_params
      %i[
        teacher_status
      ]
    end

    def next_step
      if changing_answer?
        :check_answers
      elsif teacher_status == "yes"
        :teacher_catchment
      else
        :provider_check
      end
    end

    def previous_step
      :start
    end

    def options
      [
        OpenStruct.new(value: "yes",
                       text: "Yes",
                       link_errors: true),
        OpenStruct.new(value: "no",
                       text: "No, I’m not a teacher or school leader",
                       link_errors: false),
      ]
    end

    def requirements_met?
      true
    end
  end
end

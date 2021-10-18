module Forms
  class TeacherCatchment < Base
    attr_accessor :teacher_catchment, :teacher_catchment_country

    validates :teacher_catchment, presence: true

    def self.permitted_params
      %i[
        teacher_catchment
        teacher_catchment_country
      ]
    end

    def next_step
      if changing_answer?
        if answers_will_change?
          :provider_check
        else
          :check_answers
        end
      else
        :provider_check
      end
    end

    def previous_step
      :are_you_a_teacher
    end

    def options

      [
        OpenStruct.new(value: "england",
                       text: "England",
                       link_errors: true),
        OpenStruct.new(value: "scotland",
                       text: "Scotland",
                       link_errors: false),
        OpenStruct.new(value: "wales",
                       text: "Wales",
                       link_errors: false),
        OpenStruct.new(value: "northern_ireland",
                       text: "Northern Ireland",
                       link_errors: false),
        OpenStruct.new(value: "jersey_guernsey_isle_of_man",
                       text: "Jersey, Guernsey or the Isle of Man",
                       link_errors: false),
        OpenStruct.new(value: "another",
                       text: "Another country",
                       link_errors: false),
      ]
    end
  end
end

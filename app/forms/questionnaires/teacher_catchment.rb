module Questionnaires
  class TeacherCatchment < Base
    attr_accessor :teacher_catchment, :teacher_catchment_country

    validates :teacher_catchment, presence: true, inclusion: { in: %w[england another] }

    def self.permitted_params
      %i[
        teacher_catchment
        teacher_catchment_country
      ]
    end

    def after_save
      return if teacher_catchment == "another"

      wizard.store["teacher_catchment_country"] = nil
    end

    def return_to_regular_flow_on_change?
      true
    end

    def next_step
      if changing_answer?
        if answers_will_change?
          :work_setting
        else
          :check_answers
        end
      else
        :work_setting
      end
    end

    def previous_step
      :provider_check
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :teacher_catchment,
          options:,
        ),
      ]
    end

    def options
      [
        build_option_struct(value: "england", label: "Yes", link_errors: true),
        build_option_struct(value: "another", label: "No"),
      ]
    end
  end
end

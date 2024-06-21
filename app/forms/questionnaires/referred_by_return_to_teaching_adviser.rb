module Questionnaires
  class ReferredByReturnToTeachingAdviser < Base
    attr_accessor :referred_by_return_to_teaching_adviser

    validates :referred_by_return_to_teaching_adviser, presence: true, inclusion: { in: %w[yes no] }

    def self.permitted_params
      %i[referred_by_return_to_teaching_adviser]
    end

    def next_step
      case referred_by_return_to_teaching_adviser
      when "yes"
        :choose_your_npq
      when "no"
        :work_setting
      end
    end

    def previous_step
      :teacher_catchment
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :referred_by_return_to_teaching_adviser,
          options:,
        ),
      ]
    end

    def options
      [
        build_option_struct(value: "yes", label: "Yes", link_errors: true),
        build_option_struct(value: "no", label: "No"),
      ]
    end
  end
end

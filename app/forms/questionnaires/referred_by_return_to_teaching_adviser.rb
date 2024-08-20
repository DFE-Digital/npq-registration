module Questionnaires
  class ReferredByReturnToTeachingAdviser < Base
    attr_accessor :referred_by_return_to_teaching_adviser

    validates :referred_by_return_to_teaching_adviser, presence: true, inclusion: { in: %w[yes no] }

    def self.permitted_params
      %i[referred_by_return_to_teaching_adviser]
    end

    def next_step
      :choose_your_npq
    end

    def previous_step
      :teacher_catchment
    end

    def after_save
      wizard.store["employer_name"] = "Return to teaching adviser referral" if referred_by_return_to_teaching_adviser == "yes"
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

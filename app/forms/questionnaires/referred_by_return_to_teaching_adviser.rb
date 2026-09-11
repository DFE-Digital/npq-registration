module Questionnaires
  class ReferredByReturnToTeachingAdviser < Base
    attribute :referred_by_return_to_teaching_adviser

    validates :referred_by_return_to_teaching_adviser, presence: true, inclusion: { in: %w[yes no] }

    def self.permitted_params
      %i[referred_by_return_to_teaching_adviser]
    end

    def previous_step
      if query_store.course.ehco?
        :ehco_new_headteacher
      elsif query_store.course.senco?
        :senco_start_date
      elsif query_store.course.npqlpm?
        if query_store.maths_understanding?
          :maths_eligibility_teaching_for_mastery
        else
          :maths_understanding_of_approach
        end
      else
        :work_setting
      end
    end

    def next_step
      if eligible_for_funding?
        if query_store.course.ehco?
          :ehco_possible_funding
        else
          :possible_funding
        end
      else
        :ineligible_for_funding
      end
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

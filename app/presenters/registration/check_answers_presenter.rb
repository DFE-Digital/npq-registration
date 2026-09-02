module Registration
  class CheckAnswersPresenter
    include DfE::Wizard::CheckAnswersPresenter

    def answers
      [
        row_for(:course_start_date, :course_start_cohort, label: "Course start"),
      ]
    end

    def format_value(attribute, value)
      case attribute
      when :course_start_cohort
        Questionnaires::CourseStartDate::OPTIONS.dig(value, :cohort_description)
      else
        value.to_s
      end
    end

  private

    def t(key)
      I18n.t(store[key], scope: "helpers.label.registration_wizard.#{key}_options")
    end
  end
end

module Registration
  class CheckAnswersPresenter
    Answer = Struct.new(:key, :value, :change_step)

    delegate_missing_to :@store

    attr_reader :store

    def initialize(store)
      @store = store
    end

    def answers
      array = []

      array << Answer.new("Course start", course_start, :course_start_cohort)

      array
    end

  private

    def course_start
      Questionnaires::CourseStartDate::OPTIONS.dig(store["course_start_cohort"], :cohort_description)
    end

    def t(key)
      I18n.t(store[key], scope: "helpers.label.registration_wizard.#{key}_options")
    end
  end
end
